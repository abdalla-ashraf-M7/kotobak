import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/database_helper.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../theme/app_colors.dart';
import '../../controllers/library_view_controller.dart';
import '../../controllers/book_controller.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/book_card.dart';
import '../widgets/book_carousel.dart';
import '../widgets/book_progress_indicator.dart';

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
          borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
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
              Get.toNamed('/edit-book', arguments: book);
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

  Widget _buildGridView(List<Map<String, dynamic>> books) {
    final screenWidth = MediaQuery.of(Get.context!).size.width;
    final itemWidth = (screenWidth - (3 * AppConstants.defaultPadding)) / 2;
    final itemHeight = itemWidth * 1.5;

    return AnimationLimiter(
      child: GridView.builder(
        padding: EdgeInsets.all(AppConstants.defaultPadding),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: itemWidth / (itemHeight + 32),
          crossAxisSpacing: AppConstants.defaultPadding,
          mainAxisSpacing: AppConstants.defaultPadding,
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
                child: BookCard(
                  book: book,
                  onTap: () => Get.toNamed('/reader', arguments: {
                    'bookId': book['id'],
                    'filePath': book['filePath'],
                  }),
                  onLongPress: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) => _buildBookOptions(context, book),
                    );
                  },
                  width: itemWidth,
                  height: itemHeight,
                  showProgress: true,
                  showTitle: true,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> books) {
    return AnimationLimiter(
      child: ListView.builder(
        padding: EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Padding(
                  padding: EdgeInsets.only(bottom: AppConstants.defaultPadding),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                        onTap: () => Get.toNamed('/reader', arguments: {
                          'bookId': book['id'],
                          'filePath': book['filePath'],
                        }),
                        onLongPress: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (context) => _buildBookOptions(context, book),
                          );
                        },
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(AppConstants.defaultRadius),
                                bottomLeft: Radius.circular(AppConstants.defaultRadius),
                              ),
                              child: Hero(
                                tag: 'book_${book['id']}',
                                child: book['coverImagePath'] != null
                                    ? Image.file(
                                        File(book['coverImagePath']!),
                                        width: 80,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 80,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          gradient: AppColors.primaryGradient,
                                        ),
                                        child: Center(
                                          child: Text(
                                            book['title'][0].toUpperCase(),
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
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                    if (book['progress'] != null) ...[
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          BookProgressIndicator(
                                            progress: book['progress'],
                                            size: 32,
                                            showText: true,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Progress',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: AppColors.onSurface.withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
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
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCarouselView(List<Map<String, dynamic>> books) {
    return BookCarousel(
      books: books,
      onBookTap: (bookId) {
        final book = books.firstWhere((b) => b['id'] == bookId);
        Get.toNamed('/reader', arguments: {
          'bookId': book['id'],
          'filePath': book['filePath'],
        });
      },
      onBookLongPress: (book) {
        showModalBottomSheet(
          context: Get.context!,
          backgroundColor: Colors.transparent,
          builder: (context) => _buildBookOptions(context, book),
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
                      viewController.viewMode.value == ViewMode.list ? Icons.view_carousel : Icons.view_list,
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
            child: viewController.viewMode.value == ViewMode.list ? _buildListView(filteredBooks) : _buildCarouselView(filteredBooks),
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
}
