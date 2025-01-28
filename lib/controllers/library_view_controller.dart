import 'package:get/get.dart';

enum ViewMode { list, grid }

enum SortBy { title, author, lastRead, progress }

class LibraryViewController extends GetxController {
  final Rx<ViewMode> viewMode = ViewMode.list.obs;
  final Rx<SortBy> sortBy = SortBy.title.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;

  void toggleViewMode() {
    viewMode.value = viewMode.value == ViewMode.list ? ViewMode.grid : ViewMode.list;
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
        final author = book['author'].toString().toLowerCase();
        final query = searchQuery.value.toLowerCase();
        return title.contains(query) || author.contains(query);
      }).toList();
    }

    // Apply sorting
    filteredBooks.sort((a, b) {
      switch (sortBy.value) {
        case SortBy.title:
          return a['title'].toString().compareTo(b['title'].toString());
        case SortBy.author:
          return a['author'].toString().compareTo(b['author'].toString());
        case SortBy.lastRead:
          return (b['lastRead'] ?? 0).compareTo(a['lastRead'] ?? 0);
        case SortBy.progress:
          return (b['progress'] ?? 0).compareTo(a['progress'] ?? 0);
      }
    });

    return filteredBooks;
  }
}
