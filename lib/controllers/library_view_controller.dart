import 'package:get/get.dart';
import 'book_controller.dart';

enum ViewMode { list, grid, carousel }

enum SortBy { title, lastRead, progress }

class LibraryViewController extends GetxController {
  final Rx<ViewMode> viewMode = ViewMode.grid.obs;
  final Rx<SortBy> sortBy = SortBy.lastRead.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;

  void toggleViewMode() {
    switch (viewMode.value) {
      case ViewMode.list:
        viewMode.value = ViewMode.carousel;
        break;
      case ViewMode.grid:
        viewMode.value = ViewMode.carousel;
        break;
      case ViewMode.carousel:
        viewMode.value = ViewMode.list;
        break;
    }
  }

  void setSortBy(SortBy sort) {
    sortBy.value = sort;
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  void toggleSearch() {
    isSearching.value = !isSearching.value;
    if (!isSearching.value) {
      searchQuery.value = '';
    }
  }

  List<Map<String, dynamic>> filterAndSortBooks(List<Map<String, dynamic>> books) {
    var filteredBooks = books;

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filteredBooks = books.where((book) {
        final title = book['title'].toString().toLowerCase();
        final query = searchQuery.value.toLowerCase();
        return title.contains(query);
      }).toList();
    }

    // Apply sorting
    filteredBooks.sort((a, b) {
      switch (sortBy.value) {
        case SortBy.title:
          return a['title'].toString().compareTo(b['title'].toString());
        case SortBy.lastRead:
          return (b['lastRead'] ?? 0).compareTo(a['lastRead'] ?? 0);
        case SortBy.progress:
          return (b['progress'] ?? 0.0).compareTo(a['progress'] ?? 0.0);
      }
    });

    return filteredBooks;
  }

  void deleteBook(String bookId) async {
    try {
      await Get.find<BookController>().deleteBook(bookId);
    } catch (e) {
      print('Error deleting book: $e');
    }
  }
}
