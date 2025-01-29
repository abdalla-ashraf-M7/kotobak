import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../theme/app_colors.dart';
import '../../controllers/book_controller.dart';
import 'dart:io';

class ReaderScreen extends StatefulWidget {
  @override
  _ReaderScreenState createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final BookController bookController = Get.find<BookController>();
  late PdfViewerController _pdfViewerController;
  late PdfTextSearchResult _searchResult;
  bool showControls = true;
  bool showSearchBar = false;
  bool isLoading = true;
  String? errorMessage;
  final TextEditingController _searchController = TextEditingController();
  bool _isSelectionMode = true;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _searchResult = PdfTextSearchResult();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePdfViewer();
    });
  }

  Future<void> _initializePdfViewer() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading PDF: $e';
      });
    }
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
    });
  }

  void _showBookmarks() {
    // Show bookmarks dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bookmarks'),
        content: Text('Bookmarks feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showThumbnails() {
    // Show thumbnails dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Page Thumbnails'),
        content: Text('Page thumbnails feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? filePath = Get.arguments['filePath'];
    final String bookId = Get.arguments['bookId'];

    if (filePath == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Reader'),
        ),
        body: Center(
          child: Text('No PDF file selected.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: !showSearchBar
            ? Text('Reader')
            : TextField(
                controller: _searchController,
                style: TextStyle(color: AppColors.onPrimary),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: AppColors.onPrimary.withOpacity(0.6)),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    _searchResult = _pdfViewerController.searchText(value);
                    setState(() {});
                  }
                },
              ),
        actions: !showSearchBar
            ? [
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => setState(() => showSearchBar = true),
                ),
                IconButton(
                  icon: Icon(Icons.bookmark_add),
                  onPressed: () {
                    final currentPage = _pdfViewerController.pageNumber;
                    bookController.addBookmark(bookId, currentPage - 1);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Bookmark added')),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.touch_app),
                  onPressed: _toggleSelectionMode,
                ),
              ]
            : [
                IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      showSearchBar = false;
                      _searchController.clear();
                      _searchResult.clear();
                    });
                  },
                ),
                if (_searchResult.hasResult)
                  IconButton(
                    icon: Icon(Icons.keyboard_arrow_up),
                    onPressed: () => _searchResult.previousInstance(),
                  ),
                if (_searchResult.hasResult)
                  IconButton(
                    icon: Icon(Icons.keyboard_arrow_down),
                    onPressed: () => _searchResult.nextInstance(),
                  ),
              ],
      ),
      body: Stack(
        children: [
          if (isLoading)
            Center(child: CircularProgressIndicator())
          else if (errorMessage != null)
            Center(child: Text(errorMessage!))
          else
            SfPdfViewer.file(
              File(filePath),
              controller: _pdfViewerController,
              onPageChanged: (PdfPageChangedDetails details) {
                final progress = details.newPageNumber / _pdfViewerController.pageCount;
                bookController.updateProgress(bookId, progress);
                bookController.addReadingHistory(bookId, details.newPageNumber - 1);
              },
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                setState(() {
                  isLoading = false;
                });
              },
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                setState(() {
                  isLoading = false;
                  errorMessage = details.error;
                });
              },
              enableTextSelection: _isSelectionMode,
              enableDocumentLinkAnnotation: true,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              enableDoubleTapZooming: true,
              pageSpacing: 4,
            ),
          if (showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: Icon(Icons.bookmark_outline, color: Colors.white),
                      onPressed: _showBookmarks,
                    ),
                    IconButton(
                      icon: Icon(Icons.view_sidebar_outlined, color: Colors.white),
                      onPressed: _showThumbnails,
                    ),
                    IconButton(
                      icon: Icon(Icons.zoom_out, color: Colors.white),
                      onPressed: () {
                        _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel - 0.25;
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.zoom_in, color: Colors.white),
                      onPressed: () {
                        _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel + 0.25;
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.skip_next, color: Colors.white),
                      onPressed: () {
                        final pageController = TextEditingController();
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Go to Page'),
                            content: TextField(
                              controller: pageController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Page Number',
                                hintText: '1 - ${_pdfViewerController.pageCount}',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  final page = int.tryParse(pageController.text);
                                  if (page != null && page > 0 && page <= _pdfViewerController.pageCount) {
                                    _pdfViewerController.jumpToPage(page);
                                  }
                                  Navigator.pop(context);
                                },
                                child: Text('Go'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Text(
                      '${_pdfViewerController.pageNumber} / ${_pdfViewerController.pageCount}',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.black54,
              onPressed: () {
                setState(() {
                  showControls = !showControls;
                });
              },
              child: Icon(
                showControls ? Icons.expand_more : Icons.expand_less,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
