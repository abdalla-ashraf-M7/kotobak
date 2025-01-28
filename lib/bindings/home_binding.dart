import 'package:get/get.dart';
import '../controllers/book_controller.dart';
import '../controllers/library_view_controller.dart';

class HomeBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(BookController());
    Get.put(LibraryViewController());
  }
}
