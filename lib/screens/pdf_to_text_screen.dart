import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../services/pdf_service.dart';
import '../utils/strings.dart';
import '../mixins/processing_state_mixin.dart';

class PdfToTextScreen extends StatefulWidget {
  final PlatformFile file;
  const PdfToTextScreen({super.key, required this.file});
  @override
  State<PdfToTextScreen> createState() => _PdfToTextScreenState();
}

class _PdfToTextScreenState extends State<PdfToTextScreen> with ProcessingStateMixin {
  String? _extractedText;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _extract();
  }

  Future<void> _extract() async {
    dynamic input = kIsWeb ? widget.file.bytes : widget.file.path;
    final text = await PdfService.extractText(input);
    if (mounted) {
      if (text != null) {
        setState(() {
          _extractedText = text;
          _isLoading = false;
        });
      } else {
        showErrorSnackBar(AppStrings.errorGeneric);
        Navigator.pop(context);
      }
    }
  }

  void _copy() {
    if (_extractedText != null) {
      Clipboard.setData(ClipboardData(text: _extractedText!));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
    }
  }

  void _share() {
    if (_extractedText != null) {
      Share.share(_extractedText!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extracted Text'),
        actions: [
          if (!_isLoading) IconButton(icon: const Icon(Icons.copy), onPressed: _copy),
          if (!_isLoading) IconButton(icon: const Icon(Icons.share), onPressed: _share),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(_extractedText ?? ''),
          ),
    );
  }
}
