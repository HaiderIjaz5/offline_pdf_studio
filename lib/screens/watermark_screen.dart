import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/pdf_service.dart';
import '../utils/file_saver.dart';
import '../utils/strings.dart';
import '../utils/page_parser.dart';
import '../mixins/processing_state_mixin.dart';
import 'success_screen.dart';

import '../widgets/ad_banner.dart';

class WatermarkScreen extends StatefulWidget {
  final PlatformFile file;
  const WatermarkScreen({super.key, required this.file});
  @override
  State<WatermarkScreen> createState() => _WatermarkScreenState();
}

class _WatermarkScreenState extends State<WatermarkScreen> with ProcessingStateMixin {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _pagesController = TextEditingController();
  bool _diagonal = true;
  bool _addPageNumbers = false;
  bool _allPages = true;
  int _maxPage = 0;

  @override
  void initState() {
    super.initState();
    _loadPageCount();
  }

  Future<void> _loadPageCount() async {
    dynamic input = kIsWeb ? widget.file.bytes : widget.file.path;
    _maxPage = await PdfService.getPageCount(input);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _textController.dispose();
    _pagesController.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    List<int>? pages;
    if (!_allPages) {
      if (_maxPage == 0) {
        showErrorSnackBar('Failed to load PDF page count.');
        return;
      }
      try {
        pages = PageParser.parse(_pagesController.text, _maxPage);
      } catch (e) {
        showErrorSnackBar(e.toString().replaceAll('FormatException: ', ''));
        return;
      }
    }

    await runProcessingTask(() async {
      dynamic input = kIsWeb ? widget.file.bytes : widget.file.path;
      final Uint8List? resultBytes = await PdfService.addWatermarkAndPageNumbers(
        input,
        watermarkText: _textController.text,
        diagonal: _diagonal,
        addPageNumbers: _addPageNumbers,
        pages: pages,
      );

      if (resultBytes != null) {
        final String? savedPath = await FileSaver.saveFile(resultBytes, 'watermarked_${widget.file.name}');
        if (mounted && savedPath != null) {
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => SuccessScreen(filePath: savedPath, fileBytes: resultBytes),
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
      appBar: AppBar(title: const Text('Watermark & Page Numbers')),
      body: SafeArea(
        child: Column(
          children: [
            const AdBannerWidget(adUnitId: 'ca-app-pub-3884228712419530/9931649694'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        labelText: 'Watermark Text',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('All pages'),
                      value: _allPages,
                      onChanged: (val) => setState(() => _allPages = val),
                    ),
                    if (!_allPages) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _pagesController,
                        decoration: InputDecoration(
                          labelText: 'Pages',
                          hintText: 'e.g. 1-3, 5, 7-9',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Diagonal Placement'),
                      value: _diagonal,
                      onChanged: (val) => setState(() => _diagonal = val),
                    ),
                    SwitchListTile(
                      title: const Text('Add Page Numbers (Footer)'),
                      value: _addPageNumbers,
                      onChanged: (val) => setState(() => _addPageNumbers = val),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: (isProcessing || _maxPage == 0) ? null : _apply,
                        icon: isProcessing ? const CircularProgressIndicator() : const Icon(Icons.branding_watermark),
                        label: Text(isProcessing ? AppStrings.processing : 'Apply'),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const AdBannerWidget(),
          ],
        ),
      ),
    );
  }
}
