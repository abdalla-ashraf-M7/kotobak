import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'home_screen.dart';

class ReaderScreen extends StatefulWidget {
  @override
  _ReaderScreenState createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  int currentPage = 0;
  int totalPages = 0;
  bool showControls = true;

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
        title: Text('Reader'),
        actions: [
          IconButton(
            icon: Icon(Icons.bookmark_add),
            onPressed: () {
              bookController.addBookmark(bookId, currentPage);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Bookmark added')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: filePath,
            onRender: (pages) {
              setState(() {
                totalPages = pages!;
              });
            },
            onViewCreated: (controller) {
              controller.setPage(currentPage);
            },
            onPageChanged: (page, total) {
              setState(() {
                currentPage = page!;
                totalPages = total!;
              });
              // Update progress and reading history
              if (page != null) {
                final progress = (page + 1) / total!;
                bookController.updateProgress(bookId, progress);
                bookController.addReadingHistory(bookId, page);
              }
            },
            onError: (error) {
              print('PDF Error: $error');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to load PDF: $error')),
              );
            },
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
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.color_lens_outlined, color: Colors.white),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.text_fields, color: Colors.white),
                      onPressed: () {},
                    ),
                    Text(
                      '$currentPage / $totalPages',
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
