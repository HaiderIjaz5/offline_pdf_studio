import 'dart:async';

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
  PdfTextSearcher? _textSearcher;

  bool _isSearching = false;
  bool _hasSearched = false;
  final TextEditingController _searchController = TextEditingController();

  int _pageCount = 0;
  int _currentPage = 1;
  final GlobalKey _stackKey = GlobalKey();
  bool _showScrollPill = false;
  Timer? _hidePillTimer;

  void _onScrollActivity() {
    if (!mounted) return;
    _hidePillTimer?.cancel();
    if (!_showScrollPill) {
      setState(() {
        _showScrollPill = true;
      });
    }
    _hidePillTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _showScrollPill = false;
      });
    });
  }

double _scrollFraction() {
  if (!_controller.isReady) return 0;
  try {
    final Size doc = _controller.documentSize;
    final Rect vis = _controller.visibleRect;
    final double max = doc.height - vis.height;
    if (max <= 0) return 0;
    return (vis.top / max).clamp(0.0, 1.0).toDouble();
  } catch (_) {
    return 0;
  }
}

void _onBadgeDragUpdate(DragUpdateDetails details) {
  _onScrollActivity();
  if (!mounted) return;
  final box =
      _stackKey.currentContext?.findRenderObject() as RenderBox?;
  if (box == null) return;
  final double top = box.localToGlobal(Offset.zero).dy;
  final double height = box.size.height;
  if (height <= 0) return;
  final double fraction =
      ((details.globalPosition.dy - top) / height)
          .clamp(0.0, 1.0)
          .toDouble();
  if (!_controller.isReady) return;
  try {
    final Size doc = _controller.documentSize;
    final Rect vis = _controller.visibleRect;
    final double max = doc.height - vis.height;
    if (max <= 0) return;
    _controller.goToPosition(
      documentOffset: Offset(vis.left, fraction * max),
    );
  } catch (_) {
    return;
  }
}

  late final PdfViewerParams _params;

  void _onSearchUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScrollActivity);
    _params = PdfViewerParams(
      margin: 5,
      pageDropShadow: null,
      pagePaintCallbacks: [_paintMatches],
      onPageChanged: (pageNumber) {
        if (!mounted) return;
        final p = pageNumber;
        if (p != null && p != _currentPage) {
          setState(() {
            _currentPage = p;
          });
        }
  },
      onViewerReady: (document, controller) {
        if (!mounted) return;
        _textSearcher?.removeListener(_onSearchUpdate);
        _textSearcher?.dispose();
        _textSearcher = PdfTextSearcher(controller);
        _textSearcher!.addListener(_onSearchUpdate);
        setState(() {
          _pageCount = document.pages.length;
        });
      },
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onScrollActivity);
    _hidePillTimer?.cancel();
    _textSearcher?.removeListener(_onSearchUpdate);
    _textSearcher?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _paintMatches(Canvas canvas, Rect pageRect, PdfPage page) {
    _textSearcher?.pageTextMatchPaintCallback(canvas, pageRect, page);
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


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isLandscape =
    MediaQuery.of(context).orientation == Orientation.landscape;


    // Match counter values
    final int totalMatches = _textSearcher?.matches.length ?? 0;
    final int currentMatch =
        totalMatches == 0 ? 0 : ((_textSearcher?.currentIndex ?? 0) + 1);

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
                      _textSearcher?.startTextSearch(value,
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
  if ((_textSearcher?.isSearching ?? false) &&
      totalMatches == 0)
    const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.0),
      child: Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    )
  else
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
                  _textSearcher?.goToPrevMatch();
                },
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down),
                onPressed: () {
                  _textSearcher?.goToNextMatch();
                },
              ),
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _textSearcher?.resetTextSearch();
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
            if (!isLandscape)
              const AdBannerWidget(adUnitId: 'ca-app-pub-3884228712419530/9931649694'),
            Expanded(
                              child: Stack(
                                key: _stackKey,
                                children: [
                                  (widget.fileBytes != null)
                                      ? PdfViewer.data(
                                          widget.fileBytes!,
                                          sourceName: widget.title,
                                          passwordProvider: _askForPassword,
                                          controller: _controller,
                                          params: _params,
                                        )
                                      : (widget.filePath != null)
                                          ? PdfViewer.file(
                                              widget.filePath!,
                                              passwordProvider: _askForPassword,
                                              controller: _controller,
                                              params: _params,
                                            )
                                                  : const Center(child: Text('Invalid PDF Source')),
                                       if (_pageCount > 1)
                                         Positioned(
                                           right: 4,
                                           top: 0,
                                           bottom: 0,
                                           child: IgnorePointer(
                                             ignoring: !_showScrollPill,
                                             child: AnimatedOpacity(
                                               opacity: _showScrollPill ? 1.0 : 0.0,
                                               duration: const Duration(milliseconds: 200),
                                               child: ValueListenableBuilder<Matrix4>(
                                                 valueListenable: _controller,
                                                 builder: (context, _, __) {
                                                   return Align(
                                                     alignment: Alignment(
                                                         1.0,
                                                         -1 + 2 * _scrollFraction()),
                                                     child: GestureDetector(
                                                       onVerticalDragUpdate:
                                                           _onBadgeDragUpdate,
                                                       child: Container(
                                                         padding: const EdgeInsets
                                                             .symmetric(
                                                                 horizontal: 10,
                                                                 vertical: 6),
                                                         decoration: BoxDecoration(
                                                           color: Colors.black54,
                                                           borderRadius:
                                                               BorderRadius.circular(
                                                                   14),
                                                         ),
                                                         child: Text(
                                                           '$_currentPage / $_pageCount',
                                                           style: const TextStyle(
                                                               color: Colors.white,
                                                               fontSize: 14,
                                                               fontWeight:
                                                                   FontWeight.w700),
                                                         ),
                                                       ),
                                                     ),
                                                   );
                                                 },
                                               ),
                                             ),
                                           ),
                                         ),


                                ],
                              ),
                            ),

            if (widget.bottomActionWidget != null) widget.bottomActionWidget!,
            if (!isLandscape) const AdBannerWidget(),

          ],
        ),
      ),
    );
  }
}