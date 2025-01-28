import 'package:get/get.dart';
import '../controllers/book_controller.dart';

class UploadBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => BookController());
  }
}
