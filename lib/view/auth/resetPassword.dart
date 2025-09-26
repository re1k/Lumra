import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';
import 'package:flutter/services.dart';

class ResetPasswordDialog {
  static void show(BuildContext context, AuthController authController) {
    final TextEditingController emailController = TextEditingController();
    String? errorMessage;

    final allowedDomains = [
      "gmail.com",
      "outlook.com",
      "hotmail.com",
      "icloud.com",
      "yahoo.com",
    ];

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==== Email Label ====
                    const Text(
                      "Email Address",
                      style: TextStyle(
                        fontFamily: 'K2D',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ==== Email Field ====
                    TextFormField(
                      inputFormatters: [LengthLimitingTextInputFormatter(128)],

                      controller: emailController,
                      decoration: InputDecoration(
                        counterText: "",
                        prefixIcon: const Icon(Icons.email),
                        errorText: errorMessage,
                      ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    minimumSize: const Size(90, 40),
                  ),
                  onPressed: () async {
                    final email = emailController.text
                        .trim()
                        .toLowerCase(); // chech for remaz

                    if (email.isEmpty) {
                      setState(() {
                        errorMessage = "Please enter your email.";
                      });
                      return;
                    }

                    final domain = email.split('@').last;
                    final emailRegexStrict = RegExp(
                      r"^(?!\.)[A-Za-z0-9!#\$%&'\*\+/=\?\^_`{\|}~\.-]{1,64}(?<!\.)@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z]{2,})+$",
                    );

                    if (!allowedDomains.contains(domain) ||
                        !emailRegexStrict.hasMatch(email)) {
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
                      Get.snackbar(
                        "Email Sent",
                        "Please check your inbox to continue.",
                      );
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
