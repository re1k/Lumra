import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';
import 'package:lumra_project/view/auth/loginPage.dart';
import 'package:lumra_project/view/welcomePage.dart';

class Signoutdialog {
  static void show(BuildContext context, AuthController authController) {
    showDialog(
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
            "Confirm Sign out",
            style: TextStyle(fontFamily: 'K2D', fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to sign out?",
            style: TextStyle(
              fontFamily: 'K2D',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
              onPressed: () async {
                await authController.logout();
                Navigator.pop(context);
                Get.offAll(() => const Welcomepage());
              },
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
    );
  }
}
