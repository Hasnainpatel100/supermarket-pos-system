import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Loader {
  // Loader.showLoader();
  static void showLoader() {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
  }

  // Loader.hideLoader();
  static void hideLoader() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }
}