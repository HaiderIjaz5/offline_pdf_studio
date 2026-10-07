import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/pdf_service.dart';
import '../utils/file_saver.dart';
import '../utils/strings.dart';
import '../mixins/processing_state_mixin.dart';
import 'success_screen.dart';
import 'dart:math' as math;

import '../widgets/ad_banner.dart';

class SignPdfPlacementScreen extends StatefulWidget {
  final PlatformFile file;
  final Uint8List signatureBytes;

  const SignPdfPlacementScreen({super.key, required this.file, required this.signatureBytes});

  @override
  State<SignPdfPlacementScreen> createState() => _SignPdfPlacementScreenState();
}

class _SignPdfPlacementScreenState extends State<SignPdfPlacementScreen> with ProcessingStateMixin {
  int _maxPage = 0;
  int _currentPage = 0;
  final Map<int, Uint8List> _pageImages = {};
  
  double _xFraction = 0.5;
  double _yFraction = 0.5;
  double _widthFraction = 0.25;
  double _rotationDegrees = 0;
  
  bool _isLoadingPages = true;

  @override
  void initState() {
    super.initState();
    _initPages();
  }

  Future<void> _initPages() async {
    dynamic input = kIsWeb ? widget.file.bytes : widget.file.path;
    _maxPage = await PdfService.getPageCount(input);
    if (_maxPage > 0) {
      await _loadPage(0);
    }
    if (mounted) {
      setState(() {
        _isLoadingPages = false;
      });
    }
  }

  Future<void> _loadPage(int index) async {
    if (_pageImages.containsKey(index)) return;
    dynamic input = kIsWeb ? widget.file.bytes : widget.file.path;
    final Uint8List? bytes = await PdfService.renderPdfPageToImage(input, index + 1);
    if (bytes != null) {
      if (mounted) {
        setState(() {
          _pageImages[index] = bytes;
        });
      }
    }
  }

  Future<void> _applySignature() async {
    await runProcessingTask(() async {
      dynamic input = kIsWeb ? widget.file.bytes : widget.file.path;
      final Uint8List? resultBytes = await PdfService.addSignature(
        input,
        _currentPage,
        widget.signatureBytes,
        xFraction: _xFraction,
        yFraction: _yFraction,
        widthFraction: _widthFraction,
        rotationDegrees: _rotationDegrees,
      );

      if (resultBytes != null) {
        final String? savedPath = await FileSaver.saveFile(resultBytes, 'signed_${widget.file.name}');
        if (mounted && savedPath != null) {
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => SuccessScreen(filePath: savedPath, fileName: 'signed_${widget.file.name}', fileBytes: resultBytes),
          ));
        }
      } else {
        showErrorSnackBar(AppStrings.errorGeneric);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Place Signature (Page ${_currentPage + 1} of $_maxPage)'),
        actions: [
          TextButton(
            onPressed: isProcessing ? null : _applySignature,
            child: isProcessing 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const AdBannerWidget(adUnitId: 'ca-app-pub-3884228712419530/9931649694'),
            Expanded(
              child: _isLoadingPages
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Expanded(
                          child: PageView.builder(
                            scrollDirection: Axis.vertical,
                            itemCount: _maxPage,
                            onPageChanged: (index) {
                              setState(() {
                                _currentPage = index;
                              });
                              _loadPage(index);
                            },
                            itemBuilder: (context, index) {
                              if (!_pageImages.containsKey(index)) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              
                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  return Center(
                                    child: Image.memory(
                                      _pageImages[index]!,
                                      fit: BoxFit.contain,
                                      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                        if (frame == null) return child;
                                        
                                        return Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            child,
                                            Positioned.fill(
                                              child: LayoutBuilder(
                                                builder: (context, imgConstraints) {
                                                  final double sigWidth = imgConstraints.maxWidth * _widthFraction;
                                                  final double posX = imgConstraints.maxWidth * _xFraction;
                                                  final double posY = imgConstraints.maxHeight * _yFraction;
                                                  
                                                  return Stack(
                                                    children: [
                                                      Positioned(
                                                        left: posX,
                                                        top: posY,
                                                        child: GestureDetector(
                                                          onPanUpdate: (details) {
                                                            setState(() {
                                                              _xFraction = (_xFraction + details.delta.dx / imgConstraints.maxWidth).clamp(0.0, 1.0);
                                                              _yFraction = (_yFraction + details.delta.dy / imgConstraints.maxHeight).clamp(0.0, 1.0);
                                                            });
                                                          },
                                                          child: Transform.rotate(
                                                            angle: _rotationDegrees * math.pi / 180,
                                                            child: Image.memory(
                                                              widget.signatureBytes,
                                                              width: sigWidth,
                                                              fit: BoxFit.contain,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Theme.of(context).colorScheme.surface,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.photo_size_select_large, size: 20, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Slider(
                                      value: _widthFraction,
                                      min: 0.05,
                                      max: 1.0,
                                      onChanged: (val) => setState(() => _widthFraction = val),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.rotate_right, size: 20, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Slider(
                                      value: _rotationDegrees,
                                      min: 0,
                                      max: 360,
                                      onChanged: (val) => setState(() => _rotationDegrees = val),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.rotate_90_degrees_cw),
                                    onPressed: () {
                                      setState(() {
                                        _rotationDegrees = (_rotationDegrees + 90) % 360;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            const AdBannerWidget(),
          ],
        ),
      ),
    );
  }
}
