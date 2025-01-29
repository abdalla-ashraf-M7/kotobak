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
      appBar: _buildAppBar(),
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
              onPageChanged: _handlePageChanged,
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                setState(() => isLoading = false);
              },
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                setState(() {
                  isLoading = false;
                  errorMessage = details.error;
                });
              },
              enableTextSelection: _isSelectionMode,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              enableDoubleTapZooming: true,
              pageSpacing: 4,
            ),
          if (_isDrawingMode) _buildDrawingCanvas(),
          if (showControls) _buildControls(),
          _buildToolbar(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
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
      actions: _buildAppBarActions(),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (showSearchBar) {
      return [
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
        if (_searchResult.hasResult) ...[
          IconButton(
            icon: Icon(Icons.keyboard_arrow_up),
            onPressed: () => _searchResult.previousInstance(),
          ),
          IconButton(
            icon: Icon(Icons.keyboard_arrow_down),
            onPressed: () => _searchResult.nextInstance(),
          ),
        ],
      ];
    }

    return [
      IconButton(
        icon: Icon(Icons.search),
        onPressed: () => setState(() => showSearchBar = true),
      ),
      IconButton(
        icon: Icon(Icons.bookmark_add),
        onPressed: _addBookmark,
      ),
      PopupMenuButton<String>(
        onSelected: (tool) => setState(() => _currentTool = tool),
        itemBuilder: (context) => [
          PopupMenuItem(value: 'pen', child: Text('Pen')),
          PopupMenuItem(value: 'highlighter', child: Text('Highlighter')),
          PopupMenuItem(value: 'eraser', child: Text('Eraser')),
          PopupMenuItem(value: 'shapes', child: Text('Shapes')),
        ],
      ),
    ];
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

  void _handlePageChanged(PdfPageChangedDetails details) {
    final progress = details.newPageNumber / _pdfViewerController.pageCount;
    final bookId = Get.arguments['bookId'];
    bookController.updateProgress(bookId, progress);
    bookController.addReadingHistory(bookId, details.newPageNumber - 1);
    _loadAnnotations();
    _loadDrawingLayers();
  }

  void _addBookmark() {
    final bookId = Get.arguments['bookId'];
    final currentPage = _pdfViewerController.pageNumber;
    bookController.addBookmark(bookId, currentPage - 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bookmark added')),
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
