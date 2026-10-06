import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/pdf_viewer_scaffold.dart';

class PdfViewerScreen extends StatelessWidget {
  final String? filePath;
  final Uint8List? fileBytes;
  final bool openedFromIntent;

  const PdfViewerScreen({
    super.key, 
    this.filePath, 
    this.fileBytes,
    this.openedFromIntent = false,
  });

  @override
  Widget build(BuildContext context) {
    return PdfViewerScaffold(
      title: 'PDF Viewer',
      filePath: filePath,
      fileBytes: fileBytes,
      openedFromIntent: openedFromIntent,
    );
  }
}
