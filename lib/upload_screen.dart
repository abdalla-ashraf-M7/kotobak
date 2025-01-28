import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'home_screen.dart';

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
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      if (result != null) {
        setState(() {
          selectedFile = result;
        });
      }
    } catch (err) {
      print('Error picking document: $err');
    }
  }

  void uploadBook() {
    if (selectedFile != null) {
      bookController.addBook({
        'id': DateTime.now().toString(),
        'title': bookTitle,
        'author': bookAuthor,
        'progress': 0.0,
      });
      Get.back();
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
