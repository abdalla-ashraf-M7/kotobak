import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SelectionController extends GetxController {
  final RxBool isSelectingQuoteArea = false.obs;
  final Rx<Offset?> selectionStart = Rx<Offset?>(null);
  final Rx<Offset?> selectionEnd = Rx<Offset?>(null);
  DateTime? lastUpdate;

  void startQuoteSelection() {
    isSelectingQuoteArea.value = true;
    selectionStart.value = null;
    selectionEnd.value = null;
  }

  void handleSelectionUpdate(Offset position) {
    if (selectionStart.value == null) {
      selectionStart.value = position;
    }

    if (lastUpdate == null || DateTime.now().difference(lastUpdate!).inMilliseconds > 16) {
      selectionEnd.value = position;
      lastUpdate = DateTime.now();
      update(); // Force update to trigger rebuild
    }
  }

  void setPanStart(Offset position) {
    selectionStart.value = position;
  }

  void finalizeSelection() {
    if (selectionStart.value != null && selectionEnd.value != null) {
      isSelectingQuoteArea.value = false;
    }
  }
}
