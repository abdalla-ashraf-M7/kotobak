import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookController extends GetxController {
  static const String STORAGE_KEY = 'books_data';
  var books = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadBooks();
  }

  Future<void> loadBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedBooks = prefs.getString(STORAGE_KEY);
      if (storedBooks != null) {
        final List<dynamic> decodedBooks = json.decode(storedBooks);
        books.assignAll(decodedBooks.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      print('Error loading books: $e');
    }
  }

  Future<void> saveBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedBooks = json.encode(books.toList());
      await prefs.setString(STORAGE_KEY, encodedBooks);
    } catch (e) {
      print('Error saving books: $e');
    }
  }

  void addBook(Map<String, dynamic> book) {
    books.add(book);
    saveBooks();
    update();
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
