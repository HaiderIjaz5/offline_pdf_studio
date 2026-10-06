import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/pdf_service.dart';
import '../utils/file_saver.dart';
import '../mixins/processing_state_mixin.dart';
import '../widgets/ad_banner.dart';
import 'success_screen.dart';

class MergePreviewScreen extends StatefulWidget {
  final List<PlatformFile> files;

  const MergePreviewScreen({super.key, required this.files});

  @override
  State<MergePreviewScreen> createState() => _MergePreviewScreenState();
}

class _MergePreviewScreenState extends State<MergePreviewScreen> with ProcessingStateMixin {
  late List<PlatformFile> _files;

  @override
  void initState() {
    super.initState();
    _files = List.from(widget.files);
  }

  void _reorderFiles(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final PlatformFile file = _files.removeAt(oldIndex);
      _files.insert(newIndex, file);
    });
  }

  void _removeFile(int index) {
    setState(() {
      _files.removeAt(index);
    });
  }

  Future<void> _addMoreFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: kIsWeb,
    );

    if (result != null) {
      final existingNames = _files.map((e) => e.name).toSet();
      final existingPaths = _files.map((e) => e.path).whereType<String>().toSet();

      setState(() {
        for (var file in result.files) {
          if (existingNames.contains(file.name)) continue;
          if (file.path != null && existingPaths.contains(file.path)) continue;
          _files.add(file);
          existingNames.add(file.name);
          if (file.path != null) existingPaths.add(file.path!);
        }
      });
    }
  }

  Future<void> _mergeAndSave() async {
    await runProcessingTask(() async {
      List<String> paths = [];
      List<Uint8List> bytes = [];

      if (kIsWeb) {
        bytes = _files.map((e) => e.bytes!).toList();
      } else {
        paths = _files.map((e) => e.path!).toList();
      }

      final Uint8List? resultBytes = await PdfService.mergePdfs(paths, bytes);

      if (resultBytes != null) {
        final String? savedPath = await FileSaver.saveFile(resultBytes, 'merged_document.pdf');
        
        if (mounted && savedPath != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SuccessScreen(filePath: savedPath, fileBytes: resultBytes),
            ),
          );
        }
      } else {
        showErrorSnackBar('Failed to merge PDFs.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Merge Order',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _addMoreFiles,
            tooltip: 'Add more',
          ),
        ],
      ),
      body: Column(
        children: [
          const AdBannerWidget(adUnitId: 'ca-app-pub-3884228712419530/9931649694'),
          if (_files.isNotEmpty && _files.length < 2)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Select at least 2 PDF files to merge.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: _files.isEmpty
                ? const Center(child: Text('No files selected.'))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _files.length,
                    onReorder: _reorderFiles,
                    itemBuilder: (context, index) {
                      final file = _files[index];
                      return Card(
                        key: ValueKey(file.name + index.toString()),
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf, color: Color(0xFFD32F2F)),
                          title: Text(file.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('File ${index + 1}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeFile(index),
                              ),
                              const Icon(Icons.drag_handle, color: Colors.grey),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (isProcessing || _files.length < 2) ? null : _mergeAndSave,
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        icon: isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.save),
        label: Text(isProcessing ? 'Merging...' : 'Merge & Save'),
      ),
      bottomNavigationBar: const AdBannerWidget(),
    );
  }
}
