import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'home_screen.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  String bookTitle = '';
  String bookAuthor = '';
  FilePickerResult? selectedFile;

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
      final fileName = path.basename(sourcePath);
      final destinationPath = path.join(directory.path, 'books', fileName);

      // Create books directory if it doesn't exist
      final booksDir = Directory(path.join(directory.path, 'books'));
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      // Copy file to local storage
      final File sourceFile = File(sourcePath);
      final File destinationFile = File(destinationPath);
      await sourceFile.copy(destinationPath);

      return destinationPath;
    } catch (e) {
      print('Error saving file to local storage: $e');
      rethrow;
    }
  }

  void uploadBook() async {
    if (selectedFile != null && selectedFile!.files.single.path != null) {
      try {
        final String sourcePath = selectedFile!.files.single.path!;
        final String localFilePath = await _saveFileToLocalStorage(sourcePath);

        print('Uploading book with local file path: $localFilePath'); // Debug print

        bookController.addBook({
          'id': DateTime.now().toString(),
          'title': bookTitle,
          'author': bookAuthor,
          'progress': 0.0,
          'filePath': localFilePath,
        });

        Get.back();
      } catch (e) {
        print('Error during upload: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a PDF file')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Book'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(hintText: 'Book Title'),
              onChanged: (value) => setState(() => bookTitle = value),
            ),
            TextField(
              decoration: InputDecoration(hintText: 'Author'),
              onChanged: (value) => setState(() => bookAuthor = value),
            ),
            SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: pickDocument,
              icon: Icon(Icons.attach_file),
              label: Text(selectedFile != null ? selectedFile!.files.single.name : 'Select PDF File'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: bookTitle.isNotEmpty && bookAuthor.isNotEmpty && selectedFile != null ? uploadBook : null,
              child: Text('Upload Book'),
            ),
          ],
        ),
      ),
    );
  }
}
