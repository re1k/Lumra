import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';

class NotInterestedDialog {
  /// Shows a soft confirmation dialog for "Not interested".
  static Future<bool> show(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 24,
              ),
              title: const Text(
                "Not interested",
                style: TextStyle(
                  fontFamily: 'K2D',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: const Text(
                "Hide this activity for now?",
                style: TextStyle(
                  fontFamily: 'K2D',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(fontFamily: 'K2D', color: Colors.black87),
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
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    "Confirm",
                    style: TextStyle(
                      fontFamily: 'K2D',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
