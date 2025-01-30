import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kotobak/controllers/quote_controller.dart';
import 'package:pdf_render/pdf_render.dart';
import 'package:pdf_render/pdf_render_widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import '../../theme/app_colors.dart';
import '../../controllers/book_controller.dart';
import '../../models/annotation.dart';
import '../../database/database_helper.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:screenshot/screenshot.dart';
import '../../views/screens/quotes_screen.dart';

class ReaderScreen extends StatefulWidget {
  final String filePath;
  final String bookId;

  const ReaderScreen({
    Key? key,
    required this.filePath,
    required this.bookId,
  }) : super(key: key);

  @override
  _ReaderScreenState createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final BookController bookController = Get.find<BookController>();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final ScreenshotController screenshotController = ScreenshotController();
  final controller = PdfViewerController();
  TapDownDetails? _doubleTapDetails;
  bool showControls = true;
  bool showSearchBar = false;
  bool isLoading = true;
  String? errorMessage;
  final TextEditingController _searchController = TextEditingController();
  bool _isDrawingMode = false;
  String _drawingTool = 'pen';
  List<DrawingLayer> _drawingLayers = [];
  DrawingLayer? _currentLayer;
  final List<DrawingLayer> _undoStack = [];
  final List<DrawingLayer> _redoStack = [];
  Color _selectedColor = Colors.blue;
  double _strokeWidth = 2.0;
  double _opacity = 1.0;
  bool _isDrawingEnabled = false;
  bool isDarkMode = false;
  bool isSearchVisible = false;
  bool _isTextSelectionMode = false;
  String? _selectedText;
  bool _isSelectingQuoteArea = false;
  Offset? _selectionStart;
  Offset? _selectionEnd;

  @override
  void initState() {
    super.initState();
    Get.put(QuoteController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePdfViewer();
    });
  }

  Future<void> _captureAndSaveQuote() async {
    try {
      final image = await screenshotController.capture();
      if (image == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/quote_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(imagePath).writeAsBytes(image);

      final quote = {
        'bookId': widget.bookId,
        'pageNumber': controller.currentPageNumber,
        'imagePath': imagePath,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      await Get.find<QuoteController>().addQuote(quote);
      Get.snackbar(
        'Success',
        'Quote saved',
        duration: Duration(seconds: 1),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error saving quote: $e');
      Get.snackbar(
        'Error',
        'Failed to save quote',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  Future<void> _initializePdfViewer() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Verify file exists
      if (!await File(widget.filePath).exists()) {
        throw Exception('PDF file not found at path: ${widget.filePath}');
      }

      String pdfPath = widget.filePath;
      try {
        // Check for cached version
        final cache = await _databaseHelper.getBookCache(widget.bookId);

        if (cache != null && cache['cachedPath'] != null) {
          final cacheFile = File(cache['cachedPath']);
          if (await cacheFile.exists()) {
            pdfPath = cache['cachedPath'];
          }
        }
      } catch (e) {
        print('Cache error (non-fatal): $e');
        pdfPath = widget.filePath;
      }

      // Load drawings
      try {
        await _loadDrawingLayers();
      } catch (e) {
        print('Drawing loading error (non-fatal): $e');
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

  Future<void> _loadDrawingLayers() async {
    try {
      if (controller.isReady) {
        final layers = await _databaseHelper.getDrawingLayers(widget.bookId, controller.currentPageNumber);
        setState(() {
          _drawingLayers = layers.map((map) => DrawingLayer.fromMap(map)).toList();
        });
      }
    } catch (e) {
      print('Error loading drawing layers: $e');
    }
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

  void _toggleDrawingMode() {
    setState(() {
      _isDrawingMode = !_isDrawingMode;
      _isDrawingEnabled = _isDrawingMode;
      if (_isDrawingMode) {
        _drawingTool = 'pen';
        _selectedColor = Colors.blue;
        _strokeWidth = 2.0;
        _opacity = 1.0;
      }
    });
  }

  void _selectDrawingTool(String tool) {
    setState(() {
      _drawingTool = tool;
      switch (tool) {
        case 'pen':
          _selectedColor = Colors.blue;
          _strokeWidth = 2.0;
          _opacity = 1.0;
          break;
        case 'highlighter':
          _selectedColor = Colors.yellow;
          _strokeWidth = 20.0;
          _opacity = 0.3;
          break;
        case 'eraser':
          _strokeWidth = 20.0;
          break;
      }
    });
  }

  void _addAnnotation(AnnotationType type) async {
    final String bookId = widget.bookId;
    final annotation = Annotation(
      bookId: bookId,
      page: controller.currentPageNumber,
      type: type,
      color: _selectedColor,
      opacity: _opacity,
      points: _currentLayer?.points ?? [],
      strokeWidth: _strokeWidth,
    );
    await _databaseHelper.insertAnnotation(annotation.toMap());
  }

  @override
  Widget build(BuildContext context) {
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
                  // Search functionality will need to be implemented differently
                },
              ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: isDarkMode ? Colors.white : Colors.black),
            onSelected: (value) {
              switch (value) {
                case 'bookmark':
                  _showBookmarks();
                  break;
                case 'quotes':
                  Get.to(() => QuotesScreen(bookId: widget.bookId));
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
                value: 'quotes',
                child: Row(
                  children: [
                    Icon(Icons.format_quote, color: Colors.black87),
                    SizedBox(width: 8),
                    Text('View Quotes'),
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
            GestureDetector(
                onDoubleTapDown: (details) => _doubleTapDetails = details,
                onDoubleTap: () => controller.ready?.setZoomRatio(
                      zoomRatio: controller.zoomRatio * 1.5,
                      center: _doubleTapDetails!.localPosition,
                    ),
                child: Screenshot(
                    child: PdfViewer.openFile(
                      widget.filePath,
                      viewerController: controller,
                      onError: (error) => print(error),
                      params: PdfViewerParams(
                        padding: 2.0, // Small padding between pages
                        minScale: 1.0,
                        maxScale: 3.0,
                        layoutPages: (viewSize, pages) {
                          // Custom layout for continuous scrolling with proper spacing
                          List<Rect> rects = [];
                          double y = 0;
                          for (var page in pages) {
                            final aspectRatio = page.width / page.height;
                            final width = viewSize.width;
                            final height = width / aspectRatio;
                            rects.add(Rect.fromLTWH(0, y, width, height));
                            y += height + 4; // 4 pixels spacing between pages
                          }
                          return rects;
                        },
                      ),
                    ),
                    controller: screenshotController)),
          if (_selectedText != null)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.black87 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.copy),
                      onPressed: () {
                        if (_selectedText != null) {
                          // Copy to clipboard
                          // Clipboard.setData(ClipboardData(text: _selectedText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Text copied to clipboard')),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.highlight),
                      onPressed: () {
                        // Implement highlight functionality
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.share),
                      onPressed: () {
                        // Implement share functionality
                      },
                    ),
                  ],
                ),
              ),
            ),
          if (_isDrawingMode) _buildDrawingCanvas(),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildToolbarButton(Icons.comment_outlined, 'Comment', onTap: () {
                        // Comment functionality
                      }),
                      _buildToolbarButton(Icons.format_quote, 'Quote', onTap: () {
                        _startQuoteSelection();
                      }),
                      _buildToolbarButton(Icons.highlight_alt_outlined, 'Highlight', onTap: () {
                        setState(() {
                          _isDrawingMode = true;
                          _drawingTool = 'highlighter';
                          _selectedColor = Colors.yellow;
                          _strokeWidth = 20.0;
                          _opacity = 0.3;
                          _isDrawingEnabled = true;
                        });
                      }),
                      _buildToolbarButton(Icons.draw_outlined, 'Draw', onTap: () {
                        setState(() {
                          _isDrawingMode = true;
                          _drawingTool = 'pen';
                          _selectedColor = Colors.blue;
                          _strokeWidth = 2.0;
                          _opacity = 1.0;
                          _isDrawingEnabled = true;
                        });
                      }),
                      _buildToolbarButton(Icons.text_fields, 'Text', onTap: () {
                        // Text functionality
                      }),
                      _buildToolbarButton(Icons.more_horiz, 'More', onTap: () {
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
                  if (_isDrawingMode)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(Icons.undo),
                            onPressed: _undo,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                          IconButton(
                            icon: Icon(Icons.redo),
                            onPressed: _redo,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                          IconButton(
                            icon: Icon(Icons.color_lens),
                            onPressed: _showColorPicker,
                            color: _selectedColor,
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _isDrawingMode = false;
                                _isDrawingEnabled = false;
                              });
                            },
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!_isDrawingMode && !_isSelectingQuoteArea)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onLongPress: () {
                  // Disable long press for now since text selection isn't supported
                  // by the PDF viewer widget
                },
              ),
            ),
          if (_isSelectingQuoteArea) _buildSelectionOverlay(),
        ],
      ),
    );
  }

  Widget _buildDrawingCanvas() {
    return GestureDetector(
      onPanStart: _isDrawingEnabled ? _handleDrawingStart : null,
      onPanUpdate: _isDrawingEnabled ? _handleDrawingUpdate : null,
      onPanEnd: _isDrawingEnabled ? _handleDrawingEnd : null,
      child: CustomPaint(
        size: Size.infinite,
        painter: DrawingPainter(
          layers: [..._drawingLayers, if (_currentLayer != null) _currentLayer!],
        ),
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
          future: _databaseHelper.getBookmarks(widget.bookId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No bookmarks yet'));
            }
            return ListView.builder(
              shrinkWrap: true,
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final bookmark = snapshot.data![index];
                return ListTile(
                  leading: Icon(Icons.bookmark, color: Colors.blue),
                  title: Text('Page ${bookmark['page'] + 1}'),
                  subtitle: bookmark['note'] != null ? Text(bookmark['note']) : null,
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline),
                    onPressed: () async {
                      // await _databaseHelper.deleteBookmark(bookmark['id']);
                      Navigator.pop(context);
                      _showBookmarks(); // Refresh the list
                    },
                  ),
                  onTap: () async {
                    final controller = await this.controller;
                    await controller.ready?.goToPage(pageNumber: bookmark['page']);
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

  void _handleDrawingStart(DragStartDetails details) {
    setState(() {
      _currentLayer = DrawingLayer(
        bookId: widget.bookId,
        page: controller.currentPageNumber,
        layerName: 'Layer ${_drawingLayers.length + 1}',
        strokeColor: _drawingTool == 'eraser' ? Colors.transparent : _selectedColor,
        strokeWidth: _strokeWidth,
        opacity: _drawingTool == 'highlighter' ? 0.3 : _opacity,
        points: [details.localPosition],
      );
    });
  }

  void _handleDrawingUpdate(DragUpdateDetails details) {
    if (_currentLayer != null) {
      setState(() {
        final points = List<Offset>.from(_currentLayer!.points)..add(details.localPosition);
        _currentLayer = _currentLayer!.copyWith(points: points);
      });
    }
  }

  void _handleDrawingEnd(DragEndDetails details) async {
    if (_currentLayer != null && _currentLayer!.points.isNotEmpty) {
      if (_drawingTool == 'eraser') {
        _handleErasing(_currentLayer!.points);
      } else {
        await _saveDrawing();
      }
    }
  }

  void _handleErasing(List<Offset> eraserPoints) {
    setState(() {
      _drawingLayers.removeWhere((layer) {
        return _doStrokesIntersect(eraserPoints, layer.points);
      });
    });
    _saveDrawingState();
  }

  bool _doStrokesIntersect(List<Offset> stroke1, List<Offset> stroke2) {
    for (var point1 in stroke1) {
      for (var point2 in stroke2) {
        if ((point1 - point2).distance < _strokeWidth) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _saveDrawing() async {
    if (_currentLayer != null && _currentLayer!.points.isNotEmpty) {
      try {
        final String bookId = widget.bookId;
        final currentPage = await controller.currentPageNumber;

        if (currentPage <= 0) {
          print('Invalid page number: $currentPage');
          return;
        }

        final layer = _currentLayer!.copyWith(
          bookId: bookId,
          page: currentPage,
          createdAt: DateTime.now(),
        );

        final id = await _databaseHelper.insertDrawingLayer(layer.toMap());

        setState(() {
          _drawingLayers.add(layer.copyWith(id: id));
          _currentLayer = null;
          _undoStack.clear();
        });

        print('Drawing saved successfully for page $currentPage');
      } catch (e) {
        print('Error saving drawing: $e');
      }
    }
  }

  Future<void> _saveDrawingState() async {
    final String bookId = widget.bookId;
    final int currentPage = await controller.currentPageNumber;

    await _databaseHelper.deleteDrawingLayers(bookId, currentPage);

    for (var layer in _drawingLayers) {
      await _databaseHelper.insertDrawingLayer(layer.toMap());
    }
  }

  void _showTextSelectionToolbar(Offset point) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        point.dx,
        point.dy,
        point.dx + 1,
        point.dy + 1,
      ),
      items: [
        PopupMenuItem(
          child: Text('Copy'),
          onTap: () {
            // Implement copy functionality
          },
        ),
        PopupMenuItem(
          child: Text('Highlight'),
          onTap: () {
            // Implement highlight functionality
          },
        ),
        PopupMenuItem(
          child: Text('Share'),
          onTap: () {
            // Implement share functionality
          },
        ),
      ],
    ).then((_) {
      setState(() {
        _isTextSelectionMode = false;
      });
    });
  }

  void _startQuoteSelection() {
    setState(() {
      _isSelectingQuoteArea = true;
      _selectionStart = null;
      _selectionEnd = null;
    });
  }

  Widget _buildSelectionOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.transparent, // Add transparent overlay to prevent PDF interaction
        child: GestureDetector(
          behavior: HitTestBehavior.opaque, // This prevents interaction with layers below
          onPanStart: (details) {
            setState(() => _selectionStart = details.localPosition);
          },
          onPanUpdate: (details) {
            setState(() => _selectionEnd = details.localPosition);
          },
          onPanEnd: (_) async {
            if (_selectionStart != null && _selectionEnd != null) {
              await _captureSelectedArea();
              setState(() => _isSelectingQuoteArea = false);
            }
          },
          child: CustomPaint(
            painter: SelectionPainter(
              selectionStart: _selectionStart,
              selectionEnd: _selectionEnd,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _captureSelectedArea() async {
    if (_selectionStart == null || _selectionEnd == null) return;

    try {
      // Calculate the selection rectangle
      final rect = Rect.fromPoints(_selectionStart!, _selectionEnd!);

      // Capture the entire screen first
      final fullImage = await screenshotController.capture(
        pixelRatio: 2.0,
        delay: Duration(milliseconds: 10),
      );

      if (fullImage == null) return;

      // Create an image from the captured bytes
      final originalImage = await decodeImageFromList(fullImage);

      // Create a picture recorder to draw the cropped area
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Calculate the crop rectangle, ensuring it's within bounds
      final cropRect = Rect.fromLTWH(
        rect.left.clamp(0.0, originalImage.width.toDouble()),
        rect.top.clamp(0.0, originalImage.height.toDouble()),
        rect.width.clamp(0.0, originalImage.width.toDouble()),
        rect.height.clamp(0.0, originalImage.height.toDouble()),
      );

      // Draw only the selected portion
      canvas.drawImageRect(
        originalImage,
        cropRect,
        Rect.fromLTWH(0, 0, cropRect.width, cropRect.height),
        Paint(),
      );

      // Convert to an image
      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(
        cropRect.width.toInt(),
        cropRect.height.toInt(),
      );

      // Convert to bytes
      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final croppedBytes = byteData.buffer.asUint8List();

      // Save the cropped image
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/quote_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(imagePath).writeAsBytes(croppedBytes);

      final quote = {
        'bookId': widget.bookId,
        'pageNumber': controller.currentPageNumber,
        'imagePath': imagePath,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      await Get.find<QuoteController>().addQuote(quote);
      Get.snackbar(
        'Success',
        'Quote saved',
        duration: Duration(seconds: 1),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error saving quote: $e');
      Get.snackbar(
        'Error',
        'Failed to save quote',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
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

      if (layer.points.length == 1) {
        // Draw a dot for single points
        canvas.drawCircle(layer.points[0], layer.strokeWidth / 2, paint);
      } else {
        // Convert points to the format expected by perfect_freehand
        final points = layer.points.map((p) => Point(p.dx, p.dy)).toList();

        // Get the smoothed stroke
        final stroke = getStroke(
          points,
          size: layer.strokeWidth,
          thinning: 0.7,
          smoothing: 0.5,
          streamline: 0.5,
          simulatePressure: false,
        );

        if (stroke.isNotEmpty) {
          final path = Path();

          // Move to the first point
          path.moveTo(stroke.first.x, stroke.first.y);

          // Draw through all points
          for (var i = 1; i < stroke.length; i++) {
            path.lineTo(stroke[i].x, stroke[i].y);
          }

          // Close the path if it's a highlighter
          if (layer.opacity < 0.5) {
            path.close();
          }

          canvas.drawPath(path, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}

class SelectionPainter extends CustomPainter {
  final Offset? selectionStart;
  final Offset? selectionEnd;

  SelectionPainter({this.selectionStart, this.selectionEnd});

  @override
  void paint(Canvas canvas, Size size) {
    if (selectionStart == null || selectionEnd == null) return;

    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromPoints(selectionStart!, selectionEnd!);
    canvas.drawRect(rect, paint);

    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(SelectionPainter oldDelegate) {
    return selectionStart != oldDelegate.selectionStart || selectionEnd != oldDelegate.selectionEnd;
  }
}
