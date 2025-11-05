import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';

/// Custom Lumra-styled toast
/// Usage: ToastService.success('Your message');
/// Usage: ToastService.info('the title','Your message');

class ToastService {
  static DateTime? _lastShownAt;
  static const _debounceMs = 600;
  static void show(
    String title,
    String message, {
    bool isError = false,
    bool isSuccess = false,
    bool isInfo = false,
    SnackPosition position = SnackPosition.TOP,
  }) {
    final now = DateTime.now();
    if (_lastShownAt != null &&
        now.difference(_lastShownAt!).inMilliseconds < _debounceMs) {
      return;
    }
    _lastShownAt = now;

    //Don’t stack—replace current snackbar
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: Colors.white,
      icon: isError
          ? const Icon(Icons.error, color: BColors.error)
          : isSuccess
          ? const Icon(Icons.check, color: BColors.success)
          : null,
      borderRadius: 24,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 4),
      snackStyle: SnackStyle.FLOATING,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 4, // small soft blur
          spreadRadius: 1, // keeps it tight around the snackbar
          offset: const Offset(0, 2), // slight lift
        ),
      ],

      titleText: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }

  static void success(
    String message, {
    SnackPosition position = SnackPosition.TOP,
  }) {
    show('Success', message, isSuccess: true, position: position);
  }

  static void error(
    String message, {
    SnackPosition position = SnackPosition.TOP,
  }) {
    show('Error', message, isError: true, position: position);
  }

  static void info(
    String title,
    String message, {
    SnackPosition position = SnackPosition.TOP,
  }) {
    show(title, message, isInfo: true, position: position);
  }
}
