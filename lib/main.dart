import 'package:get/get.dart';
import 'home_screen.dart';
import 'reader_screen.dart';
import 'upload_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'My Library',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => HomeScreen()),
        GetPage(name: '/reader', page: () => ReaderScreen()),
        GetPage(name: '/upload', page: () => UploadScreen()),
      ],
    );
  }
}
