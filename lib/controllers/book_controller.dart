import 'package:get/get.dart';
import '../database/database_helper.dart';

class BookController extends GetxController {
  final DatabaseHelper _db = DatabaseHelper();
  var books = <Map<String, dynamic>>[].obs;

  @override
  void onInit() async {
    super.onInit();
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
      await loadBooks();
    } catch (e) {
      print('Error adding book: $e');
    }
  }

  Future<void> updateProgress(String bookId, double progress) async {
    try {
      await _db.updateBookProgress(bookId, progress);
      await loadBooks();
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

  Future<void> deleteBook(String bookId) async {
    try {
      await _db.deleteBook(bookId);
      await loadBooks();
    } catch (e) {
      print('Error deleting book: $e');
    }
  }
}
