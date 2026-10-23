import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
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
    final title = filePath != null ? p.basename(filePath!) : 'PDF Viewer';
    return PdfViewerScaffold(
      title: title,
      filePath: filePath,
      fileBytes: fileBytes,
      openedFromIntent: openedFromIntent,
    );
  }
}
