import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import '../services/pdf_service.dart';
import '../utils/file_saver.dart';
import '../utils/strings.dart';
import '../mixins/processing_state_mixin.dart';
import 'success_screen.dart';

class SignPdfScreen extends StatefulWidget {
  final PlatformFile file;
  const SignPdfScreen({super.key, required this.file});
  @override
  State<SignPdfScreen> createState() => _SignPdfScreenState();
}

class _SignPdfScreenState extends State<SignPdfScreen> with ProcessingStateMixin {
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();
  int _selectedPage = 0;
  String _position = 'bottomRight';

  Future<void> _save() async {
    await runProcessingTask(() async {
      try {
        final ui.Image image = await _signaturePadKey.currentState!.toImage();
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          showErrorSnackBar('Failed to render signature.');
          return;
        }
        final Uint8List signatureBytes = byteData.buffer.asUint8List();

        dynamic input = kIsWeb ? widget.file.bytes : widget.file.path;
        final Uint8List? resultBytes = await PdfService.addSignature(input, _selectedPage, signatureBytes, position: _position);

        if (resultBytes != null) {
          final String? savedPath = await FileSaver.saveFile(resultBytes, 'signed_${widget.file.name}');
          if (mounted && savedPath != null) {
            Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (_) => SuccessScreen(filePath: savedPath, fileBytes: resultBytes),
            ));
          }
        } else {
          showErrorSnackBar(AppStrings.errorGeneric);
        }
      } catch (e) {
        showErrorSnackBar('Please draw a signature first.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign PDF')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Page Number to Sign',
                hintText: 'e.g. 1',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                final page = int.tryParse(val);
                if (page != null && page > 0) {
                  _selectedPage = page - 1;
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _position,
              decoration: const InputDecoration(
                labelText: 'Position',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'bottomRight', child: Text('Bottom Right')),
                DropdownMenuItem(value: 'bottomLeft', child: Text('Bottom Left')),
                DropdownMenuItem(value: 'topRight', child: Text('Top Right')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _position = val);
              },
            ),
            const SizedBox(height: 16),
            const Text('Draw your signature below:'),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                child: SfSignaturePad(
                  key: _signaturePadKey,
                  backgroundColor: Colors.white,
                  strokeColor: Colors.black,
                  minimumStrokeWidth: 1.0,
                  maximumStrokeWidth: 4.0,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _signaturePadKey.currentState?.clear(),
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isProcessing ? null : _save,
                    icon: isProcessing ? const CircularProgressIndicator() : const Icon(Icons.check),
                    label: Text(isProcessing ? AppStrings.processing : 'Sign'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
