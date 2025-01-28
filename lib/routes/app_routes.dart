import 'package:get/get.dart';
import '../views/screens/home_screen.dart';
import '../views/screens/reader_screen.dart';
import '../views/screens/edit_book_screen.dart';
import '../views/screens/upload_screen.dart';
import '../bindings/home_binding.dart';
import '../bindings/reader_binding.dart';
import '../bindings/edit_book_binding.dart';
import '../bindings/upload_binding.dart';

abstract class Routes {
  static const home = '/';
  static const reader = '/reader';
  static const editBook = '/edit-book';
  static const upload = '/upload';
}

abstract class AppPages {
  static final pages = [
    GetPage(
      name: Routes.home,
      page: () => HomeScreen(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.reader,
      page: () => ReaderScreen(),
      binding: ReaderBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: Routes.editBook,
      page: () => EditBookScreen(),
      binding: EditBookBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: Routes.upload,
      page: () => UploadScreen(),
      binding: UploadBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
  ];
}
