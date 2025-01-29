import 'package:get/get.dart';
import '../database/database_helper.dart';

class QuoteController extends GetxController {
  final DatabaseHelper _db = DatabaseHelper();
  var quotes = <Map<String, dynamic>>[].obs;

  Future<void> loadQuotes(String bookId) async {
    try {
      final loadedQuotes = await _db.getQuotes(bookId);
      quotes.assignAll(loadedQuotes);
    } catch (e) {
      print('Error loading quotes: $e');
    }
  }

  Future<void> addQuote(Map<String, dynamic> quote) async {
    try {
      await _db.insertQuote(quote);
      await loadQuotes(quote['bookId']);
    } catch (e) {
      print('Error adding quote: $e');
    }
  }

  Future<void> deleteQuote(int quoteId) async {
    try {
      await _db.deleteQuote(quoteId);
      quotes.removeWhere((quote) => quote['id'] == quoteId);
    } catch (e) {
      print('Error deleting quote: $e');
    }
  }
}
