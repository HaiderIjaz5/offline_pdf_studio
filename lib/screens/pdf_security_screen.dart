import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/pdf_service.dart';
import '../utils/file_saver.dart';
import '../utils/strings.dart';
import '../mixins/processing_state_mixin.dart';
import 'success_screen.dart';
import '../widgets/ad_banner.dart';

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
  bool _obscure1 = true;
  bool _obscure2 = true;

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
      body: SafeArea(
        child: Column(
          children: [
            const AdBannerWidget(adUnitId: 'ca-app-pub-3884228712419530/9931649694'),
            Expanded(
              child: Padding(
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
                      obscureText: _obscure1,
                      decoration: InputDecoration(
                        labelText: widget.isProtectMode ? 'Enter Password' : 'Current Password',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceVariant,
                        suffixIcon: IconButton(
                          icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure1 = !_obscure1),
                        ),
                      ),
                    ),
                    if (widget.isProtectMode) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _pass2,
                        obscureText: _obscure2,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceVariant,
                          suffixIcon: IconButton(
                            icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscure2 = !_obscure2),
                          ),
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
            ),
            const AdBannerWidget(),
          ],
        ),
      ),
    );
  }
}
