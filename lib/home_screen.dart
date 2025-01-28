import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database/database_helper.dart';

class BookController extends GetxController {
  final DatabaseHelper _db = DatabaseHelper();
  var books = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library'),
      ),
      body: Obx(() => ListView.builder(
            itemCount: bookController.books.length,
            itemBuilder: (context, index) {
              final book = bookController.books[index];
              return GestureDetector(
                onTap: () {
                  print('Opening book with file path: ${book['filePath']}'); // Debug print
                  Get.toNamed('/reader', arguments: {
                    'bookId': book['id'],
                    'filePath': book['filePath'],
                  });
                },
                child: Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Center(
                            child: Text(
                              book['title'][0],
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book['title'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                book['author'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              LinearProgressIndicator(
                                value: book['progress'],
                                backgroundColor: Colors.grey[300],
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/upload'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
