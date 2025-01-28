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
  final bool isCarouselView;

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
    this.isCarouselView = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final card = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Book Cover with Progress
        Container(
          width: width * scale,
          height: showTitle && !isCarouselView ? height * 0.85 * scale : height * scale,
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
            fit: StackFit.expand,
            children: [
              // Book Cover
              Hero(
                tag: 'book_${book['id']}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppConstants.bookCoverRadius),
                  child: book['coverImagePath'] != null
                      ? Image.file(
                          File(book['coverImagePath']!),
                          fit: BoxFit.cover,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                          ),
                          child: Center(
                            child: Text(
                              book['title'][0].toUpperCase(),
                              style: TextStyle(
                                fontSize: height * 0.3 * scale,
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              // Progress Indicator
              if (showProgress)
                Positioned(
                  right: 8 * scale,
                  top: 8 * scale,
                  child: Container(
                    padding: EdgeInsets.all(2 * scale),
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
                    child: BookProgressIndicator(
                      progress: book['progress'] ?? 0.0,
                      size: AppConstants.gridItemProgressSize * scale * 0.7,
                      showText: false,
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
        ),
        // Title
        if (showTitle && !isCarouselView) ...[
          SizedBox(height: 4 * scale),
          Container(
            width: width * scale,
            padding: EdgeInsets.symmetric(horizontal: 4 * scale),
            child: Text(
              book['title'],
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ],
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
