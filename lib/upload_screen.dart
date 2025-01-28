import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'home_screen.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'theme/app_colors.dart';

class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  String bookTitle = '';
  String bookAuthor = '';
  FilePickerResult? selectedFile;
  File? coverImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null) {
        setState(() {
          selectedFile = result;
          print('Selected file path: ${result.files.single.path}'); // Debug print
        });
      }
    } catch (err) {
      print('Error picking document: $err');
    }
  }

  Future<String> _saveFileToLocalStorage(String sourcePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = 'book_${DateTime.now().millisecondsSinceEpoch}_${path.basename(sourcePath)}';
      final String booksPath = path.join(directory.path, 'books');
      final String destinationPath = path.join(booksPath, fileName);

      print('Source path: $sourcePath');
      print('Destination path: $destinationPath');

      // Create books directory if it doesn't exist
      final booksDir = Directory(booksPath);
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
        print('Created books directory: $booksPath');
      }

      // Copy file to local storage
      final File sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist: $sourcePath');
      }

      final File destinationFile = File(destinationPath);
      await sourceFile.copy(destinationPath);

      if (!await destinationFile.exists()) {
        throw Exception('Failed to copy file to destination: $destinationPath');
      }

      print('File successfully copied to: $destinationPath');
      return destinationPath;
    } catch (e, stackTrace) {
      print('Error saving file to local storage:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> pickCoverImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          coverImage = File(image.path);
        });
      }
    } catch (err) {
      print('Error picking cover image: $err');
    }
  }

  Future<String?> _saveCoverImage() async {
    if (coverImage == null) return null;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String coversPath = path.join(directory.path, 'covers');
      final String destinationPath = path.join(coversPath, fileName);

      print('Cover image source path: ${coverImage!.path}');
      print('Cover image destination path: $destinationPath');

      // Create covers directory if it doesn't exist
      final coversDir = Directory(coversPath);
      if (!await coversDir.exists()) {
        await coversDir.create(recursive: true);
        print('Created covers directory: $coversPath');
      }

      // Copy image to app directory
      final File destinationFile = File(destinationPath);
      await coverImage!.copy(destinationPath);

      if (!await destinationFile.exists()) {
        throw Exception('Failed to copy cover image to destination: $destinationPath');
      }

      print('Cover image successfully copied to: $destinationPath');
      return destinationPath;
    } catch (e, stackTrace) {
      print('Error saving cover image:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  void uploadBook() async {
    if (selectedFile == null || selectedFile!.files.single.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a PDF file')),
      );
      return;
    }

    try {
      final String sourcePath = selectedFile!.files.single.path!;
      print('Starting upload process for file: $sourcePath');

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        },
      );

      final String localFilePath = await _saveFileToLocalStorage(sourcePath);
      final String? coverImagePath = await _saveCoverImage();

      print('Book file saved to: $localFilePath');
      if (coverImagePath != null) {
        print('Cover image saved to: $coverImagePath');
      }

      await bookController.addBook({
        'id': DateTime.now().toString(),
        'title': bookTitle,
        'author': bookAuthor,
        'progress': 0.0,
        'filePath': localFilePath,
        'coverImagePath': coverImagePath,
      });

      // Hide loading indicator
      Navigator.of(context).pop();

      // Show success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Book uploaded successfully')),
      );
      Get.back();
    } catch (e, stackTrace) {
      // Hide loading indicator
      Navigator.of(context).pop();

      print('Error during upload:');
      print('Error: $e');
      print('Stack trace: $stackTrace');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading file: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
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
          'Upload Book',
          style: TextStyle(color: AppColors.onPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: pickCoverImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: coverImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          coverImage!,
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
                            'Add Cover Image (Optional)',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                hintText: 'Book Title',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.book, color: AppColors.primary),
              ),
              onChanged: (value) => setState(() => bookTitle = value),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Author',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.person, color: AppColors.primary),
              ),
              onChanged: (value) => setState(() => bookAuthor = value),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: pickDocument,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.attach_file),
              label: Text(
                selectedFile != null ? selectedFile!.files.single.name : 'Select PDF File',
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: bookTitle.isNotEmpty && bookAuthor.isNotEmpty && selectedFile != null ? uploadBook : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Upload Book',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
