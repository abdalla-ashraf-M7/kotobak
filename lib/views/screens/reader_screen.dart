import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart' hide Annotation;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../theme/app_colors.dart';
import '../../controllers/book_controller.dart';
import '../../models/annotation.dart';
import '../../database/database_helper.dart';
import 'dart:io';
import 'dart:ui' as ui;

class ReaderScreen extends StatefulWidget {
  @override
  _ReaderScreenState createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final BookController bookController = Get.find<BookController>();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  late PdfViewerController _pdfViewerController;
  late PdfTextSearchResult _searchResult;
  bool showControls = true;
  bool showSearchBar = false;
  bool isLoading = true;
  String? errorMessage;
  final TextEditingController _searchController = TextEditingController();
  bool _isSelectionMode = true;
  bool _isDrawingMode = false;
  List<DrawingLayer> _drawingLayers = [];
  DrawingLayer? _currentLayer;
  List<Annotation> _annotations = [];
  final List<DrawingLayer> _undoStack = [];
  final List<DrawingLayer> _redoStack = [];
  Color _selectedColor = Colors.red;
  double _strokeWidth = 3.0;
  double _opacity = 1.0;
  String _currentTool = 'pen';
  bool isDarkMode = false;
  bool isSearchVisible = false;

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

      final String bookId = Get.arguments['bookId'];
      final String filePath = Get.arguments['filePath'];

      // Verify file exists
      if (!await File(filePath).exists()) {
        throw Exception('PDF file not found at path: $filePath');
      }

      String pdfPath = filePath;
      try {
        // Check for cached version
        final cache = await _databaseHelper.getBookCache(bookId);

        if (cache != null && cache['cachedPath'] != null) {
          final cacheFile = File(cache['cachedPath']);
          if (await cacheFile.exists()) {
            pdfPath = cache['cachedPath'];
          }
        }
      } catch (e) {
        print('Cache error (non-fatal): $e');
        // If there's an error with caching, just use the original file
        pdfPath = filePath;
      }

      try {
        // Try to cache the PDF if not already cached
        final cacheDir = await getApplicationCacheDirectory();
        final cachedFile = File('${cacheDir.path}/$bookId.pdf');
        if (!await cachedFile.exists()) {
          await File(filePath).copy(cachedFile.path);
          await _databaseHelper.updateBookCache(bookId, cachedFile.path);
          pdfPath = cachedFile.path;
        }
      } catch (e) {
        print('Caching error (non-fatal): $e');
        // If caching fails, just use the original file
        pdfPath = filePath;
      }

      // Load annotations and drawings
      try {
        await _loadAnnotations();
        await _loadDrawingLayers();
      } catch (e) {
        print('Annotation loading error (non-fatal): $e');
        // Non-fatal error, continue without annotations
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Critical error in PDF viewer: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading PDF: ${e.toString()}';
      });
    }
  }

  Future<void> _loadAnnotations() async {
    final String bookId = Get.arguments['bookId'];
    final currentPage = _pdfViewerController.pageNumber;
    final annotations = await _databaseHelper.getAnnotations(bookId, currentPage);
    setState(() {
      _annotations = annotations.map((map) => Annotation.fromMap(map)).toList();
    });
  }

  Future<void> _loadDrawingLayers() async {
    final String bookId = Get.arguments['bookId'];
    final currentPage = _pdfViewerController.pageNumber;
    final layers = await _databaseHelper.getDrawingLayers(bookId, currentPage);
    setState(() {
      _drawingLayers = layers.map((map) => DrawingLayer.fromMap(map)).toList();
    });
  }

  void _undo() {
    if (_currentLayer != null && _currentLayer!.points.isNotEmpty) {
      setState(() {
        _undoStack.add(_currentLayer!);
        _currentLayer = _currentLayer!.copyWith(points: []);
      });
    }
  }

  void _redo() {
    if (_undoStack.isNotEmpty) {
      setState(() {
        final layer = _undoStack.removeLast();
        _currentLayer = layer;
        _redoStack.add(layer);
      });
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() => _selectedColor = color);
            },
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _saveDrawing() async {
    if (_currentLayer != null && _currentLayer!.points.isNotEmpty) {
      final String bookId = Get.arguments['bookId'];
      final layer = _currentLayer!.copyWith(
        bookId: bookId,
        page: _pdfViewerController.pageNumber,
      );
      await _databaseHelper.insertDrawingLayer(layer.toMap());
      setState(() {
        _drawingLayers.add(layer);
        _currentLayer = null;
      });
    }
  }

  void _addAnnotation(AnnotationType type) async {
    final String bookId = Get.arguments['bookId'];
    final annotation = Annotation(
      bookId: bookId,
      page: _pdfViewerController.pageNumber,
      type: type,
      color: _selectedColor,
      opacity: _opacity,
      points: _currentLayer?.points ?? [],
      strokeWidth: _strokeWidth,
    );
    await _databaseHelper.insertAnnotation(annotation.toMap());
    await _loadAnnotations();
  }

  @override
  Widget build(BuildContext context) {
    final String? filePath = Get.arguments['filePath'];
    final String bookId = Get.arguments['bookId'];

    if (filePath == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Reader')),
        body: Center(child: Text('No PDF file selected.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Get.back(),
        ),
        title: !isSearchVisible
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    onPressed: () => setState(() => isDarkMode = !isDarkMode),
                  ),
                  IconButton(
                    icon: Icon(Icons.view_agenda_outlined, color: isDarkMode ? Colors.white : Colors.black),
                    onPressed: () {
                      // Toggle between single and continuous page layout
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.search, color: isDarkMode ? Colors.white : Colors.black),
                    onPressed: () => setState(() => isSearchVisible = true),
                  ),
                  IconButton(
                    icon: Icon(Icons.share, color: isDarkMode ? Colors.white : Colors.black),
                    onPressed: () {
                      // Share functionality
                    },
                  ),
                ],
              )
            : TextField(
                controller: _searchController,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        isSearchVisible = false;
                        _searchController.clear();
                      });
                    },
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    _searchResult = _pdfViewerController.searchText(value);
                    setState(() {});
                  }
                },
              ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: isDarkMode ? Colors.white : Colors.black),
            onSelected: (value) {
              switch (value) {
                case 'bookmark':
                  // Add bookmark
                  break;
                case 'print':
                  // Print functionality
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'bookmark',
                child: Row(
                  children: [
                    Icon(Icons.bookmark_border, color: Colors.black87),
                    SizedBox(width: 8),
                    Text('Add Bookmark'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print, color: Colors.black87),
                    SizedBox(width: 8),
                    Text('Print'),
                  ],
                ),
              ),
            ],
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
              },
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                setState(() => isLoading = false);
              },
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                setState(() {
                  isLoading = false;
                  errorMessage = details.error;
                });
              },
              enableTextSelection: true,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              enableDoubleTapZooming: true,
              pageLayoutMode: PdfPageLayoutMode.continuous,
              scrollDirection: PdfScrollDirection.vertical,
            ),
          if (_isDrawingMode) _buildDrawingCanvas(),
          if (showControls) _buildControls(),
          _buildToolbar(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black87 : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildToolbarButton(Icons.comment_outlined, 'Comment', onTap: () {
                    // Comment functionality
                  }),
                  _buildToolbarButton(Icons.highlight_alt_outlined, 'Highlight', onTap: () {
                    // Highlight functionality
                  }),
                  _buildToolbarButton(Icons.draw_outlined, 'Draw', onTap: () {
                    // Draw functionality
                  }),
                  _buildToolbarButton(Icons.text_fields, 'Text', onTap: () {
                    // Text functionality
                  }),
                  _buildToolbarButton(Icons.edit_note, 'Fill & Sign', onTap: () {
                    // Fill & Sign functionality
                  }),
                  _buildToolbarButton(Icons.more_horiz, 'More', onTap: () {
                    // Show more tools
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Container(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: Icon(Icons.bookmark_border),
                              title: Text('Bookmarks'),
                              onTap: () {
                                Navigator.pop(context);
                                _showBookmarks();
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.zoom_in),
                              title: Text('Zoom'),
                              onTap: () {
                                Navigator.pop(context);
                                // Show zoom controls
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingCanvas() {
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _currentLayer = DrawingLayer(
            bookId: Get.arguments['bookId'],
            page: _pdfViewerController.pageNumber,
            layerName: 'Layer ${_drawingLayers.length + 1}',
            strokeColor: _selectedColor,
            strokeWidth: _strokeWidth,
            opacity: _opacity,
            points: [details.localPosition],
          );
        });
      },
      onPanUpdate: (details) {
        if (_currentLayer != null) {
          setState(() {
            final points = List<Offset>.from(_currentLayer!.points)..add(details.localPosition);
            _currentLayer = _currentLayer!.copyWith(points: points);
          });
        }
      },
      onPanEnd: (_) {
        if (_currentTool != 'eraser') {
          _saveDrawing();
        }
      },
      child: CustomPaint(
        size: Size.infinite,
        painter: DrawingPainter(
          layers: [..._drawingLayers, if (_currentLayer != null) _currentLayer!],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black54,
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isDrawingMode)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.undo, color: Colors.white),
                    onPressed: _undo,
                  ),
                  IconButton(
                    icon: Icon(Icons.redo, color: Colors.white),
                    onPressed: _redo,
                  ),
                  IconButton(
                    icon: Icon(Icons.color_lens, color: Colors.white),
                    onPressed: _showColorPicker,
                  ),
                  Slider(
                    value: _strokeWidth,
                    min: 1,
                    max: 10,
                    onChanged: (value) => setState(() => _strokeWidth = value),
                  ),
                  Slider(
                    value: _opacity,
                    min: 0.1,
                    max: 1.0,
                    onChanged: (value) => setState(() => _opacity = value),
                  ),
                ],
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(Icons.bookmark_outline, color: Colors.white),
                  onPressed: () => _showBookmarks(),
                ),
                IconButton(
                  icon: Icon(Icons.view_sidebar_outlined, color: Colors.white),
                  onPressed: () => _showThumbnails(),
                ),
                Text(
                  '${_pdfViewerController.pageNumber} / ${_pdfViewerController.pageCount}',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          FloatingActionButton(
            mini: true,
            backgroundColor: Colors.black54,
            onPressed: () => setState(() => showControls = !showControls),
            child: Icon(
              showControls ? Icons.expand_more : Icons.expand_less,
              color: Colors.white,
            ),
          ),
          if (_isDrawingMode) ...[
            SizedBox(height: 8),
            FloatingActionButton(
              mini: true,
              backgroundColor: Colors.black54,
              onPressed: () => _addAnnotation(AnnotationType.drawing),
              child: Icon(Icons.save, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isDarkMode ? Colors.white70 : Colors.black87,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black87,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookmarks() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bookmarks'),
        content: FutureBuilder<List<Map<String, dynamic>>>(
          future: _databaseHelper.getBookmarks(Get.arguments['bookId']),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text('No bookmarks yet');
            }
            return ListView.builder(
              shrinkWrap: true,
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final bookmark = snapshot.data![index];
                return ListTile(
                  title: Text('Page ${bookmark['page'] + 1}'),
                  subtitle: bookmark['note'] != null ? Text(bookmark['note']) : null,
                  onTap: () {
                    _pdfViewerController.jumpToPage(bookmark['page'] + 1);
                    Navigator.pop(context);
                  },
                );
              },
            );
          },
        ),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Page Thumbnails'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _pdfViewerController.pageCount,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  _pdfViewerController.jumpToPage(index + 1);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _pdfViewerController.pageNumber == index + 1 ? Theme.of(context).primaryColor : Colors.grey,
                    ),
                  ),
                  child: Center(
                    child: Text('${index + 1}'),
                  ),
                ),
              );
            },
          ),
        ),
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
  void dispose() {
    _pdfViewerController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingLayer> layers;

  DrawingPainter({required this.layers});

  @override
  void paint(Canvas canvas, Size size) {
    for (final layer in layers) {
      if (!layer.isVisible || layer.points.isEmpty) continue;

      final paint = Paint()
        ..color = layer.strokeColor.withOpacity(layer.opacity)
        ..strokeWidth = layer.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < layer.points.length - 1; i++) {
        if (layer.points[i] != null && layer.points[i + 1] != null) {
          canvas.drawLine(layer.points[i], layer.points[i + 1], paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
