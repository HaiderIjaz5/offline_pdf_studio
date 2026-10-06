import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/pdf_service.dart';
import '../utils/file_saver.dart';
import '../utils/strings.dart';
import '../mixins/processing_state_mixin.dart';
import 'success_screen.dart';

class WatermarkScreen extends StatefulWidget {
  final PlatformFile file;
  const WatermarkScreen({super.key, required this.file});
  @override
  State<WatermarkScreen> createState() => _WatermarkScreenState();
}

class _WatermarkScreenState extends State<WatermarkScreen> with ProcessingStateMixin {
  final TextEditingController _textController = TextEditingController();
  bool _diagonal = true;
  bool _addPageNumbers = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    await runProcessingTask(() async {
      dynamic input = kIsWeb ? widget.file.bytes : widget.file.path;
      final Uint8List? resultBytes = await PdfService.addWatermarkAndPageNumbers(
        input,
        watermarkText: _textController.text,
        diagonal: _diagonal,
        addPageNumbers: _addPageNumbers,
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Watermark Text',
                border: OutlineInputBorder(),
              ),
            ),
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
                onPressed: isProcessing ? null : _apply,
                icon: isProcessing ? const CircularProgressIndicator() : const Icon(Icons.branding_watermark),
                label: Text(isProcessing ? AppStrings.processing : 'Apply'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
