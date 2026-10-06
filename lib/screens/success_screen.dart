import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:in_app_review/in_app_review.dart';

import '../widgets/ad_banner.dart';
import '../services/settings_service.dart';
import '../utils/file_saver.dart';
import 'package:archive/archive.dart';
import 'pdf_viewer_screen.dart';
import 'package:path/path.dart' as p;

class SuccessScreen extends StatefulWidget {
  final String filePath;
  final String? internalPath;
  final Uint8List? fileBytes;
  final List<Uint8List>? multiFileBytes;
  final bool isImage;
  final String operation;

  const SuccessScreen({
    super.key,
    required this.filePath,
    this.internalPath,
    this.fileBytes,
    this.multiFileBytes,
    this.isImage = false,
    this.operation = 'Processed PDF',
  });

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  @override
  void initState() {
    super.initState();
    _handlePostSuccessOperations();
  Future<void> _handlePostSuccessOperations() async {
    if (!kIsWeb && widget.filePath != 'Web Download') {
      final fileName = p.basename(widget.filePath);
      
      String? internalPath = widget.internalPath;
      if (internalPath == null) {
        if (widget.fileBytes != null) {
          internalPath = await FileSaver.saveAppCopy(widget.fileBytes!, fileName);
        } else if (widget.multiFileBytes != null) {
          final archive = Archive();
          for (int i = 0; i < widget.multiFileBytes!.length; i++) {
            archive.addFile(ArchiveFile('page_${i+1}.png', widget.multiFileBytes![i].length, widget.multiFileBytes![i]));
          }
          final zipData = ZipEncoder().encode(archive);
          if (zipData != null) {
            internalPath = await FileSaver.saveAppCopy(zipData, fileName);
          }
        }
      }
      
      await SettingsService.addRecentFile(fileName, internalPath ?? widget.filePath, widget.operation);
    }
    
    final bool shouldAsk = await SettingsService.incrementAndCheckReview();
    if (shouldAsk) {
      final InAppReview inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        inAppReview.requestReview();
      }
    }
  }

  void _share() {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing not supported on Web.')));
      return;
    }
    final file = File(widget.filePath);
    if (file.existsSync()) {
      Share.shareXFiles([XFile(widget.filePath)]);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File not found for sharing.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Task Complete'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const AdBannerWidget(adUnitId: 'ca-app-pub-3884228712419530/9931649694'),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFA5D6A7), width: 2),
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF2E7D32),
                            size: 80,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Success! File Saved.',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        
                        if (!kIsWeb && widget.filePath != 'Web Download')
                          Text(
                            (widget.filePath.startsWith('/document/') || widget.filePath.startsWith('content://'))
                                ? 'Your file has been processed locally and saved securely to the location you selected.'
                                : 'Your file has been processed locally and saved securely to:\n${widget.filePath}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                  height: 1.5,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 48),

                        if (widget.fileBytes != null || widget.multiFileBytes != null)
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton.icon(
                              onPressed: () {
                                if (widget.multiFileBytes != null && widget.multiFileBytes!.isNotEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      backgroundColor: Colors.black87,
                                      child: Stack(
                                        children: [
                                          PageView.builder(
                                            itemCount: widget.multiFileBytes!.length,
                                            itemBuilder: (context, index) {
                                              return InteractiveViewer(
                                                child: Image.memory(widget.multiFileBytes![index]),
                                              );
                                            },
                                          ),
                                          Positioned(
                                            top: 10,
                                            right: 10,
                                            child: IconButton(
                                              icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                              onPressed: () => Navigator.pop(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                } else if (widget.isImage) {
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      child: Stack(
                                        alignment: Alignment.topRight,
                                        children: [
                                          InteractiveViewer(
                                            child: Image.memory(widget.fileBytes!),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                            onPressed: () => Navigator.pop(context),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PdfViewerScreen(
                                        fileBytes: widget.fileBytes,
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.preview_rounded),
                              label: Text(
                                widget.multiFileBytes != null ? 'Preview Images' : 'Preview File',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              foregroundColor: Theme.of(context).colorScheme.onSecondary,
                            ),
                            onPressed: _share,
                            icon: const Icon(Icons.share),
                            label: const Text('Share File', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text(
                              'Back to Dashboard',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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