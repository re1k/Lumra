import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';

class ResetPasswordDialog {
  static void show(BuildContext context, AuthController authController) {
    final TextEditingController emailController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 24,
              ),
              title: const Text(
                "Reset Password",
                style: TextStyle(
                  fontFamily: 'K2D',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email),
                        labelText: "Email Address",
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (errorMessage != null)
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                  ],
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
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () async {
                    final email = emailController.text.trim();

                    if (email.isEmpty) {
                      setState(() {
                        errorMessage = "Please enter your email.";
                      });
                      return;
                    }

                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                    if (!emailRegex.hasMatch(email)) {
                      setState(() {
                        errorMessage = "The email address is not valid.";
                      });
                      return;
                    }

                    final check = await authController.checkIfEmailExists(
                      email,
                    );
                    if (check != null) {
                      setState(() {
                        errorMessage = check;
                      });
                      return;
                    }

                    final result = await authController.resetPassword(email);
                    if (result == null) {
                      Navigator.pop(context);
                      Get.snackbar("Success", "Check your inbox ");
                    } else {
                      setState(() {
                        errorMessage = result;
                      });
                    }
                  },
                  child: const Text(
                    "Send",
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
      },
    );
  }
}
