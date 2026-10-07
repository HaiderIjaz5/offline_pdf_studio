import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/pdf_service.dart';
import '../utils/file_saver.dart';
import '../utils/page_parser.dart';
import '../widgets/pdf_viewer_scaffold.dart';
import '../mixins/processing_state_mixin.dart';
import 'success_screen.dart';

class PdfToImageScreen extends StatefulWidget {
  final PlatformFile file;

  const PdfToImageScreen({super.key, required this.file});

  @override
  State<PdfToImageScreen> createState() => _PdfToImageScreenState();
}

class _PdfToImageScreenState extends State<PdfToImageScreen> with ProcessingStateMixin {
  final TextEditingController _pageController = TextEditingController(text: '1');
  bool _convertAll = false;
  int _maxPage = 0;

  @override
  void initState() {
    super.initState();
    _loadPageCount();
  }

  Future<void> _loadPageCount() async {
    dynamic input = kIsWeb ? widget.file.bytes : widget.file.path;
    _maxPage = await PdfService.getPageCount(input);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _convertAndSave() async {
    List<int> pagesToConvert = [];
    if (!_convertAll) {
      if (_maxPage == 0) {
        showErrorSnackBar('Failed to load PDF page count.');
        return;
      }
      try {
        pagesToConvert = PageParser.parse(_pageController.text, _maxPage);
      } catch (e) {
        showErrorSnackBar(e.toString().replaceAll('FormatException: ', ''));
        return;
      }
    }

    await runProcessingTask(() async {
      dynamic input = kIsWeb ? widget.file.bytes : widget.file.path;
      
      if (_convertAll) {
        final List<Uint8List>? resultBytesList = await PdfService.renderAllPdfPagesToImages(input);
        
        if (resultBytesList != null && resultBytesList.isNotEmpty) {
          List<String> fileNames = List.generate(resultBytesList.length, (i) => 'page_${i+1}.png');
          final String? savedPath = await FileSaver.saveMultipleFiles(resultBytesList, fileNames, 'pdf_images.zip');
          
          if (mounted && savedPath != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => SuccessScreen(
                  filePath: savedPath,
                  fileName: 'pdf_images.zip',
                  multiFileBytes: resultBytesList,
                ),
              ),
            );
          }
        } else {
          showErrorSnackBar('Failed to extract images.');
        }
      } else {
        if (pagesToConvert.length == 1) {
          final int pageNumber = pagesToConvert.first;
          final Uint8List? resultBytes = await PdfService.renderPdfPageToImage(input, pageNumber);

          if (resultBytes != null) {
            final String? savedPath = await FileSaver.saveFile(resultBytes, 'page_$pageNumber.png');
            
            if (mounted && savedPath != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => SuccessScreen(
                    filePath: savedPath,
                    fileName: 'page_$pageNumber.png',
                    fileBytes: resultBytes,
                    isImage: true,
                  ),
                ),
              );
            }
          } else {
            showErrorSnackBar('Failed to extract page as image.');
          }
        } else {
          final List<Uint8List>? resultBytesList = await PdfService.renderPdfPagesToImages(input, pagesToConvert);
          
          if (resultBytesList != null && resultBytesList.isNotEmpty) {
            List<String> fileNames = List.generate(resultBytesList.length, (i) => 'page_${pagesToConvert[i]}.png');
            final String? savedPath = await FileSaver.saveMultipleFiles(resultBytesList, fileNames, 'pdf_images.zip');
            
            if (mounted && savedPath != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => SuccessScreen(
                    filePath: savedPath,
                    fileName: 'pdf_images.zip',
                    multiFileBytes: resultBytesList,
                  ),
                ),
              );
            }
          } else {
            showErrorSnackBar('Failed to extract images.');
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PdfViewerScaffold(
      title: 'Export PDF to Image',
      filePath: widget.file.path,
      fileBytes: widget.file.bytes,
      bottomActionWidget: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pageController,
                    enabled: !_convertAll,
                    decoration: InputDecoration(
                      labelText: 'Pages',
                      hintText: 'e.g. 1-3, 5, 7-9',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: (isProcessing || _maxPage == 0) ? null : _convertAndSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  icon: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.image),
                  label: Text(isProcessing ? 'Processing' : (_convertAll ? 'Export All' : 'Export')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                setState(() => _convertAll = !_convertAll);
              },
              child: Row(
                children: [
                  Checkbox(
                    value: _convertAll,
                    onChanged: (val) => setState(() => _convertAll = val ?? false),
                  ),
                  const Text('Convert entire PDF to images'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
