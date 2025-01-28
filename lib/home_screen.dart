import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database/database_helper.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'theme/app_colors.dart';

class BookController extends GetxController {
  final DatabaseHelper _db = DatabaseHelper();
  var books = <Map<String, dynamic>>[].obs;

  @override
  void onInit() async {
    super.onInit();
    // Check database schema
    await _db.checkTableSchema();
    loadBooks();
  }

  Future<void> loadBooks() async {
    try {
      final loadedBooks = await _db.getBooks();
      books.assignAll(loadedBooks);
    } catch (e) {
      print('Error loading books: $e');
    }
  }

  Future<void> addBook(Map<String, dynamic> book) async {
    try {
      await _db.insertBook(book);
      await loadBooks(); // Reload books from database
    } catch (e) {
      print('Error adding book: $e');
    }
  }

  Future<void> updateProgress(String bookId, double progress) async {
    try {
      await _db.updateBookProgress(bookId, progress);
      await loadBooks(); // Reload to update UI
    } catch (e) {
      print('Error updating progress: $e');
    }
  }

  Future<void> addBookmark(String bookId, int page, {String? note}) async {
    try {
      await _db.insertBookmark(bookId, page, note: note);
    } catch (e) {
      print('Error adding bookmark: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getBookmarks(String bookId) async {
    try {
      return await _db.getBookmarks(bookId);
    } catch (e) {
      print('Error getting bookmarks: $e');
      return [];
    }
  }

  Future<void> addReadingHistory(String bookId, int page) async {
    try {
      await _db.addReadingHistory(bookId, page);
    } catch (e) {
      print('Error adding reading history: $e');
    }
  }
}

final BookController bookController = Get.put(BookController());

class HomeScreen extends StatelessWidget {
  Future<void> _refreshBooks() async {
    await bookController.loadBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: Text(
          'My Library',
          style: TextStyle(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: AppColors.onPrimary),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: Icon(Icons.sort, color: AppColors.onPrimary),
            onPressed: () {
              // TODO: Implement sort functionality
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshBooks,
        child: Obx(() => AnimationLimiter(
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: bookController.books.length,
                itemBuilder: (context, index) {
                  final book = bookController.books[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: GestureDetector(
                          onTap: () {
                            print('Opening book with file path: ${book['filePath']}');
                            Get.toNamed('/reader', arguments: {
                              'bookId': book['id'],
                              'filePath': book['filePath'],
                            });
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                  child: book['coverImagePath'] != null
                                      ? Image.file(
                                          File(book['coverImagePath']),
                                          width: 100,
                                          height: 140,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 100,
                                          height: 140,
                                          decoration: BoxDecoration(
                                            gradient: AppColors.primaryGradient,
                                          ),
                                          child: Center(
                                            child: Text(
                                              book['title'][0],
                                              style: TextStyle(
                                                fontSize: 32,
                                                color: AppColors.onPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          book['title'],
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          book['author'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            LinearProgressIndicator(
                                              value: book['progress'],
                                              backgroundColor: AppColors.secondaryContainer,
                                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              '${(book['progress'] * 100).toInt()}% completed',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.secondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/upload'),
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: AppColors.onPrimary),
      ),
    );
  }
}
