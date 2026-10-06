import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/pdf_service.dart';
import '../utils/file_saver.dart';
import '../mixins/processing_state_mixin.dart';
import '../widgets/ad_banner.dart';
import 'success_screen.dart';
import 'package:gal/gal.dart';

class ImageToPdfScreen extends StatefulWidget {
  final List<PlatformFile> images;

  const ImageToPdfScreen({super.key, required this.images});

  @override
  State<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> with ProcessingStateMixin {
  late List<PlatformFile> _images;

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.images);
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final PlatformFile image = _images.removeAt(oldIndex);
      _images.insert(newIndex, image);
    });
  }

  Future<void> _convertToPdf() async {
    await runProcessingTask(() async {
      List<dynamic> inputs = kIsWeb
          ? _images.map((e) => e.bytes!).toList()
          : _images.map((e) => e.path!).toList();

      final Uint8List? resultBytes = await PdfService.imagesToPdf(inputs);

      if (resultBytes != null) {
        final String? savedPath = await FileSaver.saveFile(resultBytes, 'converted_document.pdf');
        
        if (mounted && savedPath != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SuccessScreen(filePath: savedPath, fileBytes: resultBytes),
            ),
          );
        }
      } else {
        showErrorSnackBar('Failed to convert images to PDF.');
      }
    });
  }

  Future<void> _saveToGallery() async {
    await runProcessingTask(() async {
      try {
        bool hasAccess = await Gal.hasAccess();
        if (!hasAccess) {
          hasAccess = await Gal.requestAccess();
        }
        if (hasAccess) {
          for (var file in _images) {
            if (file.path != null) {
              await Gal.putImage(file.path!);
            }
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Saved to Gallery!'), backgroundColor: Colors.green),
            );
          }
        } else {
          showErrorSnackBar('Permission denied to save to gallery.');
        }
      } catch (e) {
        showErrorSnackBar('Failed to save to gallery: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Image Order',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: 'Save Images to Gallery',
            onPressed: isProcessing ? null : _saveToGallery,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const AdBannerWidget(adUnitId: 'ca-app-pub-3884228712419530/9931649694'),
          Expanded(
            child: _images.isEmpty
                ? const Center(child: Text('No images selected.'))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _images.length,
                    onReorder: _reorderImages,
                    itemBuilder: (context, index) {
                      final file = _images[index];
                      return Card(
                        key: ValueKey(file.name + index.toString()),
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: SizedBox(
                            width: 50,
                            height: 50,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: (kIsWeb && file.bytes != null)
                                  ? Image.memory(file.bytes!, fit: BoxFit.cover, cacheWidth: 150)
                                  : (file.path != null)
                                      ? Image.file(File(file.path!), fit: BoxFit.cover, cacheWidth: 150)
                                      : const Icon(Icons.image),
                            ),
                          ),
                          title: Text(file.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('Image ${index + 1}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _images.removeAt(index);
                                  });
                                },
                              ),
                              const Icon(Icons.drag_handle, color: Colors.grey),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isProcessing ? null : _convertToPdf,
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        icon: isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.picture_as_pdf),
        label: Text(isProcessing ? 'Converting...' : 'Convert to PDF'),
      ),
      bottomNavigationBar: const AdBannerWidget(),
    );
  }
}
