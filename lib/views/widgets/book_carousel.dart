import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
    setState(() {
      _currentPage = _pageController.page ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = Get.height;
    final itemHeight = screenHeight * AppConstants.carouselViewHeight;

    return SizedBox(
      height: itemHeight,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.books.length,
        itemBuilder: (context, index) {
          final book = widget.books[index];
          final scale = 1.0 - ((_currentPage - index).abs() * 0.2).clamp(0.0, 0.4);
          final opacity = 1.0 - ((_currentPage - index).abs() * 0.5).clamp(0.0, 0.7);

          return TweenAnimationBuilder(
            duration: Duration(milliseconds: 300),
            tween: Tween(begin: scale, end: scale),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: opacity,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: BookCard(
                      book: book,
                      onTap: () => widget.onBookTap(book['id']),
                      onLongPress: () => widget.onBookLongPress(book),
                      width: Get.width * AppConstants.carouselViewWidth,
                      height: itemHeight,
                      scale: 1.0,
                      showProgress: false,
                      showTitle: false,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
