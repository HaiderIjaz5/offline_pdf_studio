import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/pdf_service.dart';
import '../utils/file_saver.dart';
import '../utils/strings.dart';
import '../mixins/processing_state_mixin.dart';
import 'success_screen.dart';

class PdfSecurityScreen extends StatefulWidget {
  final PlatformFile file;
  final bool isProtectMode;
  const PdfSecurityScreen({super.key, required this.file, this.isProtectMode = true});
  @override
  State<PdfSecurityScreen> createState() => _PdfSecurityScreenState();
}

class _PdfSecurityScreenState extends State<PdfSecurityScreen> with ProcessingStateMixin {
  final TextEditingController _pass1 = TextEditingController();
  final TextEditingController _pass2 = TextEditingController();

  @override
  void dispose() {
    _pass1.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<void> _process() async {
    final pass = _pass1.text;
    if (pass.isEmpty) {
      showErrorSnackBar('Please enter a password.');
      return;
    }
    if (widget.isProtectMode && pass != _pass2.text) {
      showErrorSnackBar('Passwords do not match.');
      return;
    }
    if (widget.isProtectMode && pass.length < 4) {
      showErrorSnackBar('Password must be at least 4 characters.');
      return;
    }

    await runProcessingTask(() async {
      dynamic input = kIsWeb ? widget.file.bytes : widget.file.path;
      Uint8List? resultBytes;
      
      if (widget.isProtectMode) {
        resultBytes = await PdfService.protectPdf(input, pass);
      } else {
        resultBytes = await PdfService.unlockPdf(input, pass);
      }

      if (resultBytes != null) {
        final String prefix = widget.isProtectMode ? 'protected_' : 'unlocked_';
        final String? savedPath = await FileSaver.saveFile(resultBytes, '$prefix${widget.file.name}');
        if (mounted && savedPath != null) {
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => SuccessScreen(filePath: savedPath, fileBytes: resultBytes),
          ));
        }
      } else {
        showErrorSnackBar(widget.isProtectMode ? AppStrings.errorGeneric : 'Incorrect password or corrupted file.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isProtectMode ? 'Protect PDF' : 'Unlock PDF')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (widget.isProtectMode)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text('Warning: A forgotten password cannot be recovered offline.', style: TextStyle(color: Colors.red)),
              ),
            TextField(
              controller: _pass1,
              obscureText: true,
              decoration: InputDecoration(
                labelText: widget.isProtectMode ? 'Enter Password' : 'Current Password',
                border: const OutlineInputBorder(),
              ),
            ),
            if (widget.isProtectMode) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _pass2,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isProcessing ? null : _process,
                icon: isProcessing ? const CircularProgressIndicator() : const Icon(Icons.security),
                label: Text(isProcessing ? AppStrings.processing : (widget.isProtectMode ? 'Protect' : 'Unlock')),
              ),
            )
          ],
        ),
      ),
    );
  }
}
