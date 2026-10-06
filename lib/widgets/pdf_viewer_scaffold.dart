import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
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
  final PdfViewerController _pdfViewerController = PdfViewerController();
  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  
  int _currentPage = 1;
  int _pageCount = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
                  border: InputBorder.none,
                ),
                onSubmitted: (String value) {
                  _searchResult = _pdfViewerController.searchText(value);
                  setState(() {});
                },
              )
            : Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
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
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _searchResult.clear();
                setState(() {
                  _isSearching = false;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up),
              onPressed: () {
                _searchResult.previousInstance();
                setState(() {});
              },
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: () {
                _searchResult.nextInstance();
                setState(() {});
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
                if (_pdfViewerController.zoomLevel > 1.0) {
                  _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel - 0.5;
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: () {
                _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel + 0.5;
              },
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: (_pageCount > 0 && widget.filePath != null && !kIsWeb) 
                  ? () => Share.shareXFiles([XFile(widget.filePath!)])
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
                ? SfPdfViewer.memory(
                    widget.fileBytes!,
                    controller: _pdfViewerController,
                    onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                      setState(() {
                        _pageCount = details.document.pages.count;
                      });
                    },
                    onPageChanged: (PdfPageChangedDetails details) {
                      setState(() {
                        _currentPage = details.newPageNumber;
                      });
                    },
                  )
                : (widget.filePath != null)
                    ? SfPdfViewer.file(
                        File(widget.filePath!),
                        controller: _pdfViewerController,
                        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                          setState(() {
                            _pageCount = details.document.pages.count;
                          });
                        },
                        onPageChanged: (PdfPageChangedDetails details) {
                          setState(() {
                            _currentPage = details.newPageNumber;
                          });
                        },
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
