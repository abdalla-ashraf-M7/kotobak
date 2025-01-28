import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_colors.dart';
import '../../controllers/book_controller.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/book_progress_indicator.dart';

class EditBookScreen extends StatefulWidget {
  const EditBookScreen({Key? key}) : super(key: key);

  @override
  _EditBookScreenState createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  final BookController bookController = Get.find<BookController>();
  late TextEditingController titleController;
  late TextEditingController authorController;
  late Map<String, dynamic> book;

  @override
  void initState() {
    super.initState();
    book = Get.arguments;
    titleController = TextEditingController(text: book['title']);
    authorController = TextEditingController(text: book['author']);
  }

  @override
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    book['title'] = titleController.text;
    book['author'] = authorController.text;
    await bookController.updateBook(book['id'], book);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: Text(
          'Edit Book',
          style: TextStyle(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: AppColors.onPrimary),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Hero(
                tag: 'book_${book['id']}',
                child: Container(
                  width: 200,
                  height: 300,
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
                            titleController.text[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 60,
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
            SizedBox(height: 24),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: authorController,
              decoration: InputDecoration(
                labelText: 'Author',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 24),
            Center(
              child: BookProgressIndicator(
                progress: book['progress'] ?? 0.0,
                size: 100,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
