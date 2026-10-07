import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import '../widgets/ad_banner.dart';
import '../services/settings_service.dart';
import '../main.dart';
import '../utils/strings.dart';

import 'pdf_viewer_screen.dart';
import 'merge_preview_screen.dart';
import 'split_preview_screen.dart';
import 'compress_preview_screen.dart';
import 'image_to_pdf_screen.dart';
import 'pdf_to_image_screen.dart';
import 'privacy_policy_screen.dart';
import 'organize_pages_screen.dart';
import 'watermark_screen.dart';
import 'pdf_security_screen.dart';
import 'sign_pdf_screen.dart';
import 'pdf_to_text_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _recentFiles = [];

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    final recents = await SettingsService.getRecentFiles();
    if (mounted) {
      setState(() {
        _recentFiles = recents;
      });
    }
  }

  Future<void> _openRecentFile(String path) async {
    if (File(path).existsSync()) {
      String mimeType = '*/*';
      final lowerPath = path.toLowerCase();
      if (lowerPath.endsWith('.pdf')) {
        mimeType = 'application/pdf';
      } else if (lowerPath.endsWith('.png') || lowerPath.endsWith('.jpg') || lowerPath.endsWith('.jpeg')) {
        mimeType = 'image/*';
      } else if (lowerPath.endsWith('.zip')) {
        mimeType = 'application/zip';
      }

      final result = await OpenFilex.open(path, type: mimeType);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File no longer exists.')));
      }
      _removeRecentFile(path);
    }
  }

  Future<void> _removeRecentFile(String path) async {
    await SettingsService.removeRecentFile(path);
    _loadRecents();
  }

  Future<void> _toggleTheme() async {
    final current = themeNotifier.value;
    ThemeMode nextMode;
    if (current == ThemeMode.system) nextMode = ThemeMode.light;
    else if (current == ThemeMode.light) nextMode = ThemeMode.dark;
    else nextMode = ThemeMode.system;

    themeNotifier.value = nextMode;
    await SettingsService.setThemeMode(nextMode.toString().split('.').last);
  }

  void _handleToolAction(BuildContext context, String title) async {
    try {
      if (title == 'Scan Image') {
        List<String> pictures = await CunningDocumentScanner.getPictures(scannerSource: ScannerSource.cameraAndGallery) ?? [];
        if (pictures.isNotEmpty && context.mounted) {
          List<PlatformFile> platformFiles = pictures.map((path) => PlatformFile(
            name: path.split('/').last,
            size: 0,
            path: path,
          )).toList();
          await Navigator.push(context, MaterialPageRoute(builder: (_) => ImageToPdfScreen(images: platformFiles)));
        }
      } else {
        FilePickerResult? result = await FilePicker.pickFiles(
          allowMultiple: title == 'Merge PDFs',
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          withData: kIsWeb,
        );
        
        if (result != null && context.mounted) {
          if (title == 'Merge PDFs' && result.files.length < 2) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least 2 PDF files to merge.')));
            return;
          }
          
          Widget? screen;
          if (title == 'Merge PDFs') screen = MergePreviewScreen(files: result.files);
          else if (title == 'Split PDF') screen = SplitPreviewScreen(file: result.files.single);
          else if (title == 'Compress PDF') screen = CompressPreviewScreen(file: result.files.single);
          else if (title == 'PDF to Image') screen = PdfToImageScreen(file: result.files.single);
          else if (title == 'View PDF') screen = PdfViewerScreen(filePath: kIsWeb ? null : result.files.single.path, fileBytes: kIsWeb ? result.files.single.bytes : null);
          else if (title == 'Organize Pages') screen = OrganizePagesScreen(file: result.files.single);
          else if (title == 'Watermark') screen = WatermarkScreen(file: result.files.single);
          else if (title == 'Protect PDF') screen = PdfSecurityScreen(file: result.files.single, isProtectMode: true);
          else if (title == 'Unlock PDF') screen = PdfSecurityScreen(file: result.files.single, isProtectMode: false);
          else if (title == 'Sign PDF') screen = SignPdfScreen(file: result.files.single);
          else if (title == 'Extract Text') screen = PdfToTextScreen(file: result.files.single);

          if (screen != null) {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    _loadRecents();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = theme.colorScheme.surface;
    final onSurfaceColor = theme.colorScheme.onSurface;
    final primaryColor = theme.colorScheme.primary;

    final tools = [
      {'title': 'View PDF', 'subtitle': 'Open and read PDF files', 'icon': Icons.picture_as_pdf, 'badge': null},
      {'title': 'Scan Image', 'subtitle': 'Scan documents with camera', 'icon': Icons.document_scanner_outlined, 'badge': 'Fast'},
      {'title': 'PDF to Image', 'subtitle': 'Extract pages as JPEG/PNG', 'icon': Icons.image, 'badge': null},
      {'title': 'Sign PDF', 'subtitle': 'Draw your signature on a page', 'icon': Icons.draw, 'badge': 'New'},
      {'title': 'Split PDF', 'subtitle': 'Extract specific pages easily', 'icon': Icons.call_split_rounded, 'badge': null},
      {'title': 'Merge PDFs', 'subtitle': 'Combine multiple files into one', 'icon': Icons.call_merge_rounded, 'badge': 'Popular'},
      {'title': 'Organize Pages', 'subtitle': 'Reorder, rotate, or delete pages', 'icon': Icons.layers, 'badge': 'New'},
      {'title': 'Compress PDF', 'subtitle': 'Shrink file size for sharing', 'icon': Icons.compress_rounded, 'badge': 'Fast'},
      {'title': 'Watermark', 'subtitle': 'Add text and page numbers', 'icon': Icons.branding_watermark, 'badge': 'New'},
      {'title': 'Extract Text', 'subtitle': 'Extract text from PDF pages', 'icon': Icons.text_snippet, 'badge': 'New'},
      {'title': 'Protect PDF', 'subtitle': 'Encrypt with a password', 'icon': Icons.lock, 'badge': null},
      {'title': 'Unlock PDF', 'subtitle': 'Remove existing password', 'icon': Icons.lock_open, 'badge': null},
    ];

    IconData themeIcon = Icons.brightness_auto;
    if (themeNotifier.value == ThemeMode.light) themeIcon = Icons.light_mode;
    else if (themeNotifier.value == ThemeMode.dark) themeIcon = Icons.dark_mode;

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 48,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 26),
                );
              },
            ),
            const SizedBox(width: 12),
            Text(
              'PDF Scanner & Tools Offline',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5, color: onSurfaceColor),
            ),
          ],
        ),
        backgroundColor: surfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(themeIcon, color: onSurfaceColor.withOpacity(0.7)),
            tooltip: 'Toggle Theme',
            onPressed: _toggleTheme,
          ),
          IconButton(
            icon: Icon(Icons.privacy_tip_outlined, color: onSurfaceColor.withOpacity(0.7)),
            tooltip: 'Privacy Policy',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const AdBannerWidget(adUnitId: 'ca-app-pub-3884228712419530/9931649694'),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      if (_recentFiles.isNotEmpty) ...[
                        Text(AppStrings.recentFiles, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurfaceColor)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _recentFiles.length,
                            itemBuilder: (context, index) {
                              final file = _recentFiles[index];
                              return Dismissible(
                                key: Key(file['path']),
                                direction: DismissDirection.up,
                                onDismissed: (_) => _removeRecentFile(file['path']),
                                child: GestureDetector(
                                  onTap: () => _openRecentFile(file['path']),
                                  child: Container(
                                    width: 140,
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.grey[850] : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.insert_drive_file, color: primaryColor),
                                        const SizedBox(height: 8),
                                        Text(file['fileName'], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: onSurfaceColor)),
                                        const SizedBox(height: 4),
                                        Text(file['operation'], style: TextStyle(fontSize: 11, color: onSurfaceColor.withOpacity(0.6))),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = constraints.maxWidth > 550 ? 3 : 2;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: constraints.maxWidth > 550 ? 1.1 : 0.95,
                            ),
                            itemCount: tools.length,
                            itemBuilder: (context, index) {
                              final tool = tools[index];
                              return _ToolCard(
                                title: tool['title'] as String,
                                subtitle: tool['subtitle'] as String,
                                icon: tool['icon'] as IconData,
                                badge: tool['badge'] as String?,
                                onTap: () => _handleToolAction(context, tool['title'] as String),
                              );
                            },
                          );
                        },
                      ),
                    ],
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

class _ToolCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? badge;
  final VoidCallback onTap;

  const _ToolCard({required this.title, required this.subtitle, required this.icon, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Material(
      color: isDark ? Colors.grey[900] : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: theme.colorScheme.primary.withOpacity(0.04),
        splashColor: theme.colorScheme.primary.withOpacity(0.08),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFEEEEEE), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 26, color: theme.colorScheme.primary),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          color: theme.colorScheme.surface,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}