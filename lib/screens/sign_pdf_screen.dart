import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import '../mixins/processing_state_mixin.dart';
import 'sign_pdf_placement_screen.dart';

class SignPdfScreen extends StatefulWidget {
  final PlatformFile file;
  const SignPdfScreen({super.key, required this.file});
  @override
  State<SignPdfScreen> createState() => _SignPdfScreenState();
}

class _SignPdfScreenState extends State<SignPdfScreen> with ProcessingStateMixin {
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();
  Color _strokeColor = Colors.black;

  final List<Color> _swatches = [
    Colors.black,
    const Color(0xFF00008B), // Dark blue
    Colors.blue,
    Colors.red,
    Colors.green,
  ];

  Future<void> _next() async {
    try {
      final ui.Image image = await _signaturePadKey.currentState!.toImage();
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        showErrorSnackBar('Failed to render signature.');
        return;
      }
      final Uint8List signatureBytes = byteData.buffer.asUint8List();

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SignPdfPlacementScreen(
              file: widget.file,
              signatureBytes: signatureBytes,
            ),
          ),
        );
      }
    } catch (e) {
      showErrorSnackBar('Please draw a signature first.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw Signature'),
        actions: [
          TextButton(
            onPressed: _next,
            child: const Text('Next', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Select Ink Color:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _swatches.map((color) {
                return GestureDetector(
                  onTap: () => setState(() => _strokeColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _strokeColor == color ? Colors.grey.shade400 : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
                      ],
                    ),
                    child: _strokeColor == color
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Draw your signature below:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  color: Colors.grey.shade100, // Just a subtle background behind the pad
                ),
                child: SfSignaturePad(
                  key: _signaturePadKey,
                  backgroundColor: Colors.transparent,
                  strokeColor: _strokeColor,
                  minimumStrokeWidth: 1.0,
                  maximumStrokeWidth: 4.0,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _signaturePadKey.currentState?.clear(),
              icon: const Icon(Icons.clear),
              label: const Text('Clear Signature'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
