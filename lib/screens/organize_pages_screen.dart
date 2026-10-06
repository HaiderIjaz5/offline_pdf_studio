import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/pdf_service.dart';
import '../utils/file_saver.dart';
import '../utils/strings.dart';
import '../mixins/processing_state_mixin.dart';
import 'success_screen.dart';

class OrganizePagesScreen extends StatefulWidget {
  final PlatformFile file;
  const OrganizePagesScreen({super.key, required this.file});
  @override
  State<OrganizePagesScreen> createState() => _OrganizePagesScreenState();
}

class _OrganizePagesScreenState extends State<OrganizePagesScreen> with ProcessingStateMixin {
  List<Uint8List> _pages = [];
  bool _isLoading = true;
  List<int> _pageOrder = [];
  Map<int, int> _rotations = {};
  
  @override
  void initState() {
    super.initState();
    _loadPages();
  }
  
  Future<void> _loadPages() async {
    dynamic input = kIsWeb ? widget.file.bytes : widget.file.path;
    final images = await PdfService.renderAllPdfPagesToImages(input);
    if (images != null && mounted) {
      setState(() {
        _pages = images;
        _pageOrder = List.generate(images.length, (index) => index);
        _isLoading = false;
      });
    } else if (mounted) {
      showErrorSnackBar(AppStrings.errorOpenPdf);
      Navigator.pop(context);
    }
  }

  void _rotatePage(int originalIndex) {
    setState(() {
      _rotations[originalIndex] = ((_rotations[originalIndex] ?? 0) + 90) % 360;
    });
  }

  void _deletePage(int index) {
    setState(() {
      _pageOrder.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (_pageOrder.isEmpty) {
      showErrorSnackBar('No pages left to save.');
      return;
    }
    await runProcessingTask(() async {
      dynamic input = kIsWeb ? widget.file.bytes : widget.file.path;
      Uint8List? resultBytes = await PdfService.reorderPages(input, _pageOrder);
      
      if (resultBytes != null && _rotations.isNotEmpty) {
        Map<int, int> newRotations = {};
        for (int i = 0; i < _pageOrder.length; i++) {
          final originalIndex = _pageOrder[i];
          if (_rotations.containsKey(originalIndex) && _rotations[originalIndex]! != 0) {
            newRotations[i] = _rotations[originalIndex]!;
          }
        }
        if (newRotations.isNotEmpty) {
           resultBytes = await PdfService.rotatePages(resultBytes, newRotations) ?? resultBytes;
        }
      }

      if (resultBytes != null) {
        final String? savedPath = await FileSaver.saveFile(resultBytes, 'organized_${widget.file.name}');
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
      appBar: AppBar(title: const Text('Organize Pages')),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) 
        : Column(
          children: [
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _pageOrder.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) newIndex -= 1;
                    final item = _pageOrder.removeAt(oldIndex);
                    _pageOrder.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final originalIndex = _pageOrder[index];
                  final rotation = _rotations[originalIndex] ?? 0;
                  return Card(
                    key: ValueKey(originalIndex),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: RotatedBox(
                        quarterTurns: rotation ~/ 90,
                        child: Image.memory(_pages[originalIndex], width: 50, height: 70, fit: BoxFit.cover),
                      ),
                      title: Text('Page ${originalIndex + 1}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.rotate_right), onPressed: () => _rotatePage(originalIndex)),
                          IconButton(icon: const Icon(Icons.delete), onPressed: () => _deletePage(index)),
                          const Icon(Icons.drag_handle),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isProcessing ? null : _save,
                  icon: isProcessing ? const CircularProgressIndicator() : const Icon(Icons.save),
                  label: Text(isProcessing ? AppStrings.processing : 'Save Organized PDF'),
                ),
              ),
            )
          ],
        ),
    );
  }
}
