import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';

class CustomDialog {
  /// Shows a confirmation dialog with Cancel and Confirm buttons
  static void showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 24,
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'K2D',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'K2D',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                cancelText,
                style: const TextStyle(
                  fontFamily: 'K2D',
                  color: Colors.black87,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: BColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                minimumSize: const Size(90, 40),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: Text(
                confirmText,
                style: const TextStyle(
                  fontFamily: 'K2D',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Shows a simple dialog with only a Close button
  static Future<void> showCloseOnly(
    BuildContext context, {
    required String title,
    required String message,
    String closeText = 'Close',
  }) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 24,
          ),
          title: title.isNotEmpty
              ? Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'K2D',
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'K2D',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: BColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                minimumSize: const Size(90, 40),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                closeText,
                style: const TextStyle(
                  fontFamily: 'K2D',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Shows an error dialog with only a Close button
  static Future<void> showError(
    BuildContext context, {
    required String message,
    String closeText = 'Close',
    String title = 'Error',
  }) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 24,
          ),
          title: title.isNotEmpty
              ? Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'K2D',
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'K2D',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: BColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                minimumSize: const Size(90, 40),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                closeText,
                style: const TextStyle(
                  fontFamily: 'K2D',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
