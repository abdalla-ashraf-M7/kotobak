import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'home_screen.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../controllers/book_controller.dart';
import '../../core/constants/app_constants.dart';

class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final BookController bookController = Get.find<BookController>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  String? selectedFilePath;
  String? selectedCoverImagePath;
  bool isUploading = false;

  @override
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub'],
      );

      if (result != null) {
        setState(() {
          selectedFilePath = result.files.single.path;
          if (titleController.text.isEmpty) {
            titleController.text = result.files.single.name.split('.').first;
          }
        });
      }
    } catch (e) {
      print('Error picking file: $e');
    }
  }

  Future<void> _pickCoverImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          selectedCoverImagePath = image.path;
        });
      }
    } catch (e) {
      print('Error picking cover image: $e');
    }
  }

  Future<void> _uploadBook() async {
    if (selectedFilePath == null) {
      Get.snackbar(
        'Error',
        'Please select a book file',
        backgroundColor: AppColors.error.withOpacity(0.1),
        colorText: AppColors.error,
      );
      return;
    }

    if (titleController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a title',
        backgroundColor: AppColors.error.withOpacity(0.1),
        colorText: AppColors.error,
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      final book = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': titleController.text,
        'author': authorController.text,
        'filePath': selectedFilePath,
        'coverImagePath': selectedCoverImagePath,
        'progress': 0.0,
      };

      await bookController.addBook(book);
      Get.back();
    } catch (e) {
      print('Error uploading book: $e');
      Get.snackbar(
        'Error',
        'Failed to upload book',
        backgroundColor: AppColors.error.withOpacity(0.1),
        colorText: AppColors.error,
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: Text(
          'Add New Book',
          style: TextStyle(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickCoverImage,
                child: Container(
                  width: 200,
                  height: 300,
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
                  child: selectedCoverImagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(AppConstants.bookCoverRadius),
                          child: Image.file(
                            File(selectedCoverImagePath!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: AppColors.primary,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add Cover Image',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.upload_file,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Book File',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (selectedFilePath != null) ...[
                            SizedBox(height: 4),
                            Text(
                              selectedFilePath!.split('/').last,
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isUploading ? null : _uploadBook,
        backgroundColor: AppColors.primary,
        label: isUploading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                ),
              )
            : Text(
                'Upload Book',
                style: TextStyle(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
        icon: isUploading ? null : Icon(Icons.upload, color: AppColors.onPrimary),
      ),
    );
  }
}
