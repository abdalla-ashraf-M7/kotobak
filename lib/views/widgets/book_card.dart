import 'dart:io';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import 'book_progress_indicator.dart';
import 'delete_animation.dart';

class BookCard extends StatelessWidget {
  final Map<String, dynamic> book;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isDeleting;
  final VoidCallback? onDismissed;
  final double width;
  final double height;
  final double scale;
  final bool showProgress;
  final bool showTitle;

  const BookCard({
    Key? key,
    required this.book,
    required this.onTap,
    required this.onLongPress,
    this.isDeleting = false,
    this.onDismissed,
    required this.width,
    required this.height,
    this.scale = 1.0,
    this.showProgress = true,
    this.showTitle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width * scale,
      height: height * scale,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.bookCoverRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Book Cover
          Hero(
            tag: 'book_${book['id']}',
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppConstants.bookCoverRadius),
                image: book['coverImagePath'] != null
                    ? DecorationImage(
                        image: FileImage(File(book['coverImagePath'])),
                        fit: BoxFit.cover,
                      )
                    : null,
                gradient: book['coverImagePath'] == null ? AppColors.primaryGradient : null,
              ),
              child: book['coverImagePath'] == null
                  ? Center(
                      child: Text(
                        book['title'][0].toUpperCase(),
                        style: TextStyle(
                          fontSize: height * 0.2 * scale,
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          // Progress Indicator
          if (showProgress)
            Positioned(
              right: 10 * scale,
              bottom: 10 * scale,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(4 * scale),
                child: BookProgressIndicator(
                  progress: book['progress'] ?? 0.0,
                  size: AppConstants.gridItemProgressSize * scale,
                  showText: false,
                ),
              ),
            ),
          // Title Overlay
          if (showTitle)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(AppConstants.bookCoverRadius),
                  ),
                ),
                padding: EdgeInsets.all(12 * scale),
                child: Text(
                  book['title'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          // Tap Area
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(AppConstants.bookCoverRadius),
              splashColor: AppColors.primary.withOpacity(0.1),
              highlightColor: AppColors.primary.withOpacity(0.05),
            ),
          ),
        ],
      ),
    );

    return isDeleting && onDismissed != null
        ? DeleteAnimation(
            isDeleting: isDeleting,
            onDismissed: onDismissed!,
            child: card,
          )
        : card;
  }
}
