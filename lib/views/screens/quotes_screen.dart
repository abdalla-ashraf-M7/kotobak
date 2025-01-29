import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/quote_controller.dart';
import '../../theme/app_colors.dart';
import '../../core/constants/app_constants.dart';

class QuotesScreen extends StatelessWidget {
  final String bookId;

  QuotesScreen({required this.bookId});

  @override
  Widget build(BuildContext context) {
    final QuoteController quoteController = Get.put(QuoteController());
    quoteController.loadQuotes(bookId);

    return Scaffold(
      appBar: AppBar(
        title: Text('Book Quotes'),
        backgroundColor: AppColors.primary,
      ),
      body: Obx(() => GridView.builder(
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemCount: quoteController.quotes.length,
            itemBuilder: (context, index) {
              final quote = quoteController.quotes[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.defaultRadius)),
                        child: Image.file(
                          File(quote['imagePath']),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Page ${quote['pageNumber']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            quote['text'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          )),
    );
  }
}
