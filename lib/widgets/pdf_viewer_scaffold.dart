import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';
import 'ad_banner.dart';

class PdfViewerScaffold extends StatefulWidget {
  final String title;
  final String? filePath;
  final Uint8List? fileBytes;
  final Widget? bottomActionWidget;
  final bool openedFromIntent;

  const PdfViewerScaffold({
    super.key,
    required this.title,
    this.filePath,
    this.fileBytes,
    this.bottomActionWidget,
    this.openedFromIntent = false,
  });

  @override
  State<PdfViewerScaffold> createState() => _PdfViewerScaffoldState();
}

class _PdfViewerScaffoldState extends State<PdfViewerScaffold> {
  final PdfViewerController _controller = PdfViewerController();
  late final PdfTextSearcher _textSearcher = PdfTextSearcher(_controller);

  bool _isSearching = false;
  bool _hasSearched = false;
  final TextEditingController _searchController = TextEditingController();

  int _pageCount = 0;

  void _onSearchUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _textSearcher.addListener(_onSearchUpdate);
  }

  @override
  void dispose() {
    _textSearcher.removeListener(_onSearchUpdate);
    _textSearcher.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Shows a password dialog and returns the entered password, or null on cancel.
  Future<String?> _askForPassword() async {
    if (!mounted) return null;
    final passwordCtrl = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Password Required'),
        content: TextField(
          controller: passwordCtrl,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter PDF password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(passwordCtrl.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    passwordCtrl.dispose();
    return result;
  }

  PdfViewerParams get _params => PdfViewerParams(
        pagePaintCallbacks: [_textSearcher.pageTextMatchPaintCallback],
        onViewerReady: (document, controller) {
          if (!mounted) return;
          setState(() {
            _pageCount = document.pagesCount;
          });
        },
        passwordProvider: _askForPassword,
      );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Match counter values
    final int totalMatches = _textSearcher.matches.length;
    final int currentMatch =
        totalMatches == 0 ? 0 : (_textSearcher.currentIndex ?? 0) + 1;

    return PopScope(
      canPop: !widget.openedFromIntent,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        if (widget.openedFromIntent) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.54)),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (String value) {
                    if (value.isNotEmpty) {
                      _textSearcher.startTextSearch(value,
                          caseInsensitive: true);
                      setState(() {
                        _hasSearched = true;
                      });
                    }
                  },
                )
              : Text(
                  widget.title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                ),
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          leading: widget.openedFromIntent
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => SystemNavigator.pop(),
                )
              : null,
          actions: [
            if (_isSearching) ...[
              if (_hasSearched)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Center(
                    child: Text(
                      '$currentMatch / $totalMatches',
                      style: TextStyle(
                          fontSize: 14, color: colorScheme.onSurface),
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up),
                onPressed: () {
                  _textSearcher.goToPrevMatch();
                },
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down),
                onPressed: () {
                  _textSearcher.goToNextMatch();
                },
              ),
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _textSearcher.resetTextSearch();
                  setState(() {
                    _isSearching = false;
                    _hasSearched = false;
                  });
                },
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.zoom_out),
                onPressed: () {
                  _controller.zoomDown();
                },
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: () {
                  _controller.zoomUp();
                },
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: (_pageCount > 0 &&
                        widget.filePath != null &&
                        !kIsWeb)
                    ? () {
                        String mimeType = '*/*';
                        final lower = widget.filePath!.toLowerCase();
                        if (lower.endsWith('.pdf')) {
                          mimeType = 'application/pdf';
                        } else if (lower.endsWith('.png') ||
                            lower.endsWith('.jpg') ||
                            lower.endsWith('.jpeg')) {
                          mimeType = 'image/*';
                        } else if (lower.endsWith('.zip')) {
                          mimeType = 'application/zip';
                        }
                        Share.shareXFiles(
                            [XFile(widget.filePath!, mimeType: mimeType)]);
                      }
                    : null,
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
        body: Column(
          children: [
            const AdBannerWidget(adUnitId: 'ca-app-pub-3884228712419530/9931649694'),
            Expanded(
              child: (widget.fileBytes != null)
                  ? PdfViewer.data(
                      widget.fileBytes!,
                      sourceName: widget.title,
                      controller: _controller,
                      params: _params,
                    )
                  : (widget.filePath != null)
                      ? PdfViewer.file(
                          widget.filePath!,
                          controller: _controller,
                          params: _params,
                        )
                      : const Center(child: Text('Invalid PDF Source')),
            ),
            if (widget.bottomActionWidget != null) widget.bottomActionWidget!,
            const AdBannerWidget(),
          ],
        ),
      ),
    );
  }
}
