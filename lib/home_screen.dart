import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database/database_helper.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'theme/app_colors.dart';
import 'controllers/library_view_controller.dart';
import 'controllers/book_controller.dart';

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

  Widget _buildBookOptions(BuildContext context, Map<String, dynamic> book) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: Icon(Icons.edit, color: AppColors.primary),
            title: Text('Edit Book'),
            onTap: () {
              Navigator.pop(context);
              Get.toNamed('/upload', arguments: book);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: AppColors.error),
            title: Text('Delete Book'),
            onTap: () {
              Navigator.pop(context);
              Get.dialog(
                AlertDialog(
                  title: Text('Delete Book'),
                  content: Text('Are you sure you want to delete "${book['title']}"?'),
                  actions: [
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () => Get.back(),
                    ),
                    TextButton(
                      child: Text('Delete', style: TextStyle(color: AppColors.error)),
                      onPressed: () {
                        Get.back();
                        viewController.deleteBook(book['id']);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGridItem(Map<String, dynamic> book) {
    return GestureDetector(
      onTap: () => Get.toNamed('/reader', arguments: {
        'bookId': book['id'],
        'filePath': book['filePath'],
      }),
      onLongPress: () {
        showModalBottomSheet(
          context: Get.context!,
          backgroundColor: Colors.transparent,
          builder: (context) => _buildBookOptions(context, book),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
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
              flex: 3,
              child: Hero(
                tag: 'book_${book['id']}',
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                                fontSize: 40,
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book['title'],
                          maxLines: 2,
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
                            fontSize: 14,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildCarouselView(List<Map<String, dynamic>> books) {
    return PageView.builder(
      controller: PageController(viewportFraction: 0.8),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return AnimationConfiguration.staggeredGrid(
          position: index,
          columnCount: 1,
          duration: Duration(milliseconds: 375),
          child: ScaleAnimation(
            child: FadeInAnimation(
              child: Center(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  child: Transform.scale(
                    scale: 0.9,
                    child: _buildGridItem(book),
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
                      viewController.viewMode.value == ViewMode.list
                          ? Icons.grid_view
                          : viewController.viewMode.value == ViewMode.grid
                              ? Icons.view_carousel
                              : Icons.view_list,
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
            child: _buildViewMode(filteredBooks),
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

  Widget _buildViewMode(List<Map<String, dynamic>> books) {
    switch (viewController.viewMode.value) {
      case ViewMode.list:
        return AnimationLimiter(
          key: ValueKey('list'),
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
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
        );
      case ViewMode.grid:
        return AnimationLimiter(
          key: ValueKey('grid'),
          child: GridView.builder(
            padding: EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
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
                    child: _buildGridItem(book),
                  ),
                ),
              );
            },
          ),
        );
      case ViewMode.carousel:
        return _buildCarouselView(books);
    }
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
