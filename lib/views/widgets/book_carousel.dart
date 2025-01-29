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

class _BookCarouselState extends State<BookCarousel> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  double _currentPage = 0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: AppConstants.carouselViewWidth,
      initialPage: 0,
    )..addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    setState(() {
      _currentPage = _pageController.page ?? 0;
    });
  }

  void _animateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = Get.height;
    final itemHeight = screenHeight * AppConstants.carouselViewHeight;
    final itemWidth = Get.width * AppConstants.carouselViewWidth;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: itemHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.books.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final book = widget.books[index];
              final pageOffset = (index - _currentPage);
              final isCenter = pageOffset.abs() <= 0.5;

              // Smoothly interpolate the scale
              final scale = 1.0 - (pageOffset.abs() * 0.3).clamp(0.0, 0.4);

              // Smoothly interpolate the opacity
              final opacity = 1.0 - (pageOffset.abs() * 0.6).clamp(0.0, 0.7);

              // Smoothly interpolate the rotation angle
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
                  curve: Curves.easeOutCubic,
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
                        child: Center(
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
        Container(
          height: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.books.length, (index) {
              final isActive = index == _currentPage.round();
              final isNearActive = (index - _currentPage).abs() < 1;

              return TweenAnimationBuilder(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(
                  begin: isActive ? 0.0 : 1.0,
                  end: isActive ? 1.0 : 0.0,
                ),
                builder: (context, double value, child) {
                  return GestureDetector(
                    onTap: () => _animateToPage(index),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 3),
                      width: 8 + (24 - 8) * value,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          const Color.fromARGB(31, 207, 142, 199),
                          const Color.fromARGB(221, 164, 40, 189),
                          isNearActive ? (1 - (index - _currentPage).abs()) : 0,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          if (isActive)
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }
}
