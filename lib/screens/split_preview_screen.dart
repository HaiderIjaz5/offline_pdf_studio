import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/pdf_service.dart';
import '../utils/file_saver.dart';
import '../utils/page_parser.dart';
import '../widgets/pdf_viewer_scaffold.dart';
import '../mixins/processing_state_mixin.dart';
import 'success_screen.dart';

class SplitPreviewScreen extends StatefulWidget {
  final PlatformFile file;

  const SplitPreviewScreen({super.key, required this.file});

  @override
  State<SplitPreviewScreen> createState() => _SplitPreviewScreenState();
}

class _SplitPreviewScreenState extends State<SplitPreviewScreen> with ProcessingStateMixin {
  final TextEditingController _rangeController = TextEditingController();

  @override
  void dispose() {
    _rangeController.dispose();
    super.dispose();
  }

  Future<void> _splitAndSave() async {
    final maxPage = await PdfService.getPageCount(kIsWeb ? widget.file.bytes : widget.file.path);
    late final List<int> parsedPages;
    try {
      parsedPages = PageParser.parse(_rangeController.text, maxPage);
    } catch (e) {
      showErrorSnackBar(e.toString().replaceFirst('FormatException: ', ''));
      return;
    }
    if (parsedPages.isEmpty) {
      showErrorSnackBar('Please enter a valid page range (e.g., 1, 3, 5-7).');
      return;
    }
    final pagesToExtract = parsedPages.map((p) => p - 1).toList();

    await runProcessingTask(() async {
      dynamic input = kIsWeb ? widget.file.bytes : widget.file.path;
      final Uint8List? resultBytes = await PdfService.splitPdf(input, pagesToExtract);

      if (resultBytes != null) {
        final String? savedPath = await FileSaver.saveFile(resultBytes, 'split_document.pdf');
        
        if (mounted && savedPath != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SuccessScreen(filePath: savedPath, fileName: 'split_document.pdf', fileBytes: resultBytes),
            ),
          );
        }
      } else {
        showErrorSnackBar('Failed to split PDF.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PdfViewerScaffold(
      title: 'Split PDF',
      filePath: widget.file.path,
      fileBytes: widget.file.bytes,
      bottomActionWidget: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _rangeController,
                decoration: InputDecoration(
                  labelText: 'Pages to Extract',
                  hintText: 'e.g. 1, 3, 5-7',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: isProcessing ? null : _splitAndSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              icon: isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.call_split),
              label: Text(isProcessing ? 'Processing' : 'Split'),
            ),
          ],
        ),
      ),
    );
  }
}
