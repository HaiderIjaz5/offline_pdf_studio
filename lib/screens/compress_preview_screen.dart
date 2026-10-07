import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/pdf_service.dart';
import '../utils/file_saver.dart';
import '../widgets/pdf_viewer_scaffold.dart';
import '../mixins/processing_state_mixin.dart';
import 'success_screen.dart';

class CompressPreviewScreen extends StatefulWidget {
  final PlatformFile file;

  const CompressPreviewScreen({super.key, required this.file});

  @override
  State<CompressPreviewScreen> createState() => _CompressPreviewScreenState();
}

class _CompressPreviewScreenState extends State<CompressPreviewScreen> with ProcessingStateMixin {

  Future<void> _compressAndSave() async {
    await runProcessingTask(() async {
      dynamic input = kIsWeb ? widget.file.bytes : widget.file.path;
      final Uint8List? resultBytes = await PdfService.compressPdf(input);

      if (resultBytes != null) {
        final String? savedPath = await FileSaver.saveFile(resultBytes, 'compressed_document.pdf');
        
        if (mounted && savedPath != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SuccessScreen(filePath: savedPath, fileName: 'compressed_document.pdf', fileBytes: resultBytes),
            ),
          );
        }
      } else {
        showErrorSnackBar('Failed to compress PDF.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PdfViewerScaffold(
      title: 'Compress PDF',
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
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: isProcessing ? null : _compressAndSave,
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
                  : const Icon(Icons.compress),
              label: Text(isProcessing ? 'Processing' : 'Compress & Save'),
            ),
          ],
        ),
      ),
    );
  }
}
