import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database/database_helper.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'theme/app_colors.dart';
import 'controllers/library_view_controller.dart';

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
  final LibraryViewController viewController = Get.put(LibraryViewController());

  Future<void> _refreshBooks() async {
    await bookController.loadBooks();
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search books...',
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(Icons.search, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(Icons.close, color: AppColors.primary),
          onPressed: viewController.toggleSearch,
        ),
      ),
      onChanged: viewController.setSearchQuery,
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<SortBy>(
      icon: Icon(Icons.sort, color: AppColors.onPrimary),
      onSelected: viewController.setSortBy,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: SortBy.title,
          child: Text('Sort by Title'),
        ),
        PopupMenuItem(
          value: SortBy.author,
          child: Text('Sort by Author'),
        ),
        PopupMenuItem(
          value: SortBy.lastRead,
          child: Text('Sort by Last Read'),
        ),
        PopupMenuItem(
          value: SortBy.progress,
          child: Text('Sort by Progress'),
        ),
      ],
    );
  }

  Widget _buildBookGrid(List<Map<String, dynamic>> books) {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return AnimationConfiguration.staggeredGrid(
          position: index,
          columnCount: 2,
          duration: Duration(milliseconds: 375),
          child: ScaleAnimation(
            child: FadeInAnimation(
              child: GestureDetector(
                onTap: () => Get.toNamed('/reader', arguments: {
                  'bookId': book['id'],
                  'filePath': book['filePath'],
                }),
                child: Container(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                          child: book['coverImagePath'] != null
                              ? Image.file(
                                  File(book['coverImagePath']),
                                  fit: BoxFit.cover,
                                )
                              : Container(
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
                      ),
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book['title'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              book['author'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.secondary,
                              ),
                            ),
                            SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: book['progress'],
                              backgroundColor: AppColors.secondaryContainer,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ],
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(viewController.isSearching.value ? 120 : 60),
        child: Obx(() => AppBar(
              elevation: 0,
              backgroundColor: AppColors.primary,
              title: viewController.isSearching.value
                  ? null
                  : Text(
                      'My Library',
                      style: TextStyle(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              actions: [
                if (!viewController.isSearching.value) ...[
                  IconButton(
                    icon: Icon(Icons.search, color: AppColors.onPrimary),
                    onPressed: viewController.toggleSearch,
                  ),
                  IconButton(
                    icon: Icon(
                      viewController.viewMode.value == ViewMode.list ? Icons.grid_view : Icons.view_list,
                      color: AppColors.onPrimary,
                    ),
                    onPressed: viewController.toggleViewMode,
                  ),
                  _buildSortButton(),
                ],
              ],
              bottom: viewController.isSearching.value
                  ? PreferredSize(
                      preferredSize: Size.fromHeight(60),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: _buildSearchBar(),
                      ),
                    )
                  : null,
            )),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshBooks,
        child: Obx(() {
          final filteredBooks = viewController.filterAndSortBooks(bookController.books);
          return AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: viewController.viewMode.value == ViewMode.list
                ? AnimationLimiter(
                    child: ListView.builder(
                      key: ValueKey('list'),
                      padding: EdgeInsets.all(16),
                      itemCount: filteredBooks.length,
                      itemBuilder: (context, index) {
                        final book = filteredBooks[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildListItem(book),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : _buildBookGrid(filteredBooks),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/upload'),
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: AppColors.onPrimary),
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> book) {
    return GestureDetector(
      onTap: () => Get.toNamed('/reader', arguments: {
        'bookId': book['id'],
        'filePath': book['filePath'],
      }),
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
    );
  }
}
