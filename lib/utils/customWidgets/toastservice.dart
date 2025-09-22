import 'package:flutter/material.dart';
import 'package:get/get.dart';
/// in here a custom toast Lumra Styled :)
/// to use it just write ToastService.success('ur message');

class ToastService {
static void show(String title, String message, {bool isError = false}) {
  Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: isError ? const Color.fromARGB(255, 190, 105, 105) : const Color.fromARGB(255, 115, 165, 119),
    colorText: Colors.white,
    icon: Icon(isError ? Icons.error : Icons.check, color: Colors.white),
    borderRadius: 24,
    margin: const EdgeInsets.all(12),
    duration: const Duration(seconds: 4),
    snackStyle: SnackStyle.FLOATING,
  );
}

  // Shortcut for success
  static void success(String message) {
    show("Success", message, isError: false);
  }

  // Shortcut for error
  static void error(String message) {
    show("Error", message, isError: true);
  }
}