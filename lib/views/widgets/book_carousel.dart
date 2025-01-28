import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math';
import '../../core/constants/app_constants.dart';
import 'book_card.dart';

class BookCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> books;
  final Function(String) onBookTap;
  final Function(Map<String, dynamic>) onBookLongPress;

  const BookCarousel({
    Key? key,
    required this.books,
    required this.onBookTap,
    required this.onBookLongPress,
  }) : super(key: key);

  @override
  _BookCarouselState createState() => _BookCarouselState();
}

class _BookCarouselState extends State<BookCarousel> {
  late PageController _pageController;
  double _currentPage = 0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: AppConstants.carouselViewWidth,
      initialPage: 0,
    );
    _pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    if (_isAnimating) return;
    setState(() {
      _currentPage = _pageController.page ?? 0;
    });
  }

  void _animateToPage(int page) {
    _isAnimating = true;
    _pageController
        .animateToPage(
          page,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        )
        .then((_) => _isAnimating = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = Get.height;
    final itemHeight = screenHeight * AppConstants.carouselViewHeight;
    final itemWidth = Get.width * AppConstants.carouselViewWidth;

    return Column(
      children: [
        SizedBox(
          height: itemHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.books.length,
            onPageChanged: (page) => setState(() {}),
            itemBuilder: (context, index) {
              final book = widget.books[index];
              final isCenter = index == _currentPage.round();
              final pageOffset = (index - _currentPage);
              final scale = 1.0 - (pageOffset.abs() * 0.3).clamp(0.0, 0.4);
              final opacity = 1.0 - (pageOffset.abs() * 0.6).clamp(0.0, 0.7);
              final angle = pageOffset * -25.0 * (pi / 180.0);

              return GestureDetector(
                onTap: () {
                  if (!isCenter) {
                    _animateToPage(index);
                  } else {
                    widget.onBookTap(book['id']);
                  }
                },
                child: TweenAnimationBuilder(
                  duration: Duration(milliseconds: 300),
                  tween: Tween(begin: scale, end: scale),
                  builder: (context, double value, child) {
                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle)
                        ..scale(value),
                      alignment: pageOffset >= 0 ? Alignment.centerLeft : Alignment.centerRight,
                      child: Opacity(
                        opacity: opacity,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: isCenter ? 0 : 20,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              BookCard(
                                book: book,
                                onTap: () => widget.onBookTap(book['id']),
                                onLongPress: () => widget.onBookLongPress(book),
                                width: itemWidth,
                                height: itemHeight * 0.85,
                                scale: 1.0,
                                showProgress: isCenter,
                                showTitle: false,
                                isCarouselView: true,
                              ),
                              if (isCenter) ...[
                                SizedBox(height: 16),
                                Text(
                                  book['title'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        SizedBox(height: 20),
        // Page Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.books.length, (index) {
            final isActive = index == _currentPage.round();
            return GestureDetector(
              onTap: () => _animateToPage(index),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? Colors.black87 : Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
