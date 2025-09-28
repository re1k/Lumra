import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/controller/Registration/caregiver_controller.dart';
import 'package:lumra_project/controller/Registration/registration_controller.dart';
import 'package:lumra_project/controller/Registration/name_controller.dart';
import 'package:lumra_project/view/adhd_registration/widgets/app_button.dart';
import 'package:lumra_project/view/welcomePage.dart';
import 'dart:async';

class CaregiverInboxScreen extends StatefulWidget {
  const CaregiverInboxScreen({super.key});

  @override
  State<CaregiverInboxScreen> createState() => _CaregiverInboxScreenState();
}

class _CaregiverInboxScreenState extends State<CaregiverInboxScreen> {
  int _resendCooldown = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown() {
    setState(() {
      _resendCooldown = 60; // 60 seconds cooldown
    });

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown == 0) {
        timer.cancel();
      } else {
        setState(() {
          _resendCooldown--;
        });
      }
    });
  }

  /// Check email verification status
  Future<void> _checkEmailVerification(BuildContext context) async {
    final controller = Get.find<CaregiverController>();
    await controller.checkEmailVerificationWithNavigation(context);
  }

  /// Resend email verification
  Future<void> _resendEmailVerification(BuildContext context) async {
    try {
      // Ensure controller is registered
      if (!Get.isRegistered<CaregiverController>()) {
        Get.put(CaregiverController());
      }

      final controller = Get.find<CaregiverController>();

      // Check if user is authenticated before attempting to resend
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception(
          'No authenticated user found. Please restart the registration process.',
        );
      }

      await controller.resendVerificationEmail();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Start cooldown after successful send
        _startResendCooldown();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BColors.white,
      appBar: AppBar(backgroundColor: BColors.white),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Transform.translate(
            offset: const Offset(0, -25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // SVG Image
                SizedBox(
                  width: double.infinity,
                  child: Align(
                    alignment: const Alignment(0, 0.0),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: SvgPicture.asset(
                        'assets/images/checkinbox.svg',
                        width: 270,
                        height: 205,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Almost there!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: BColors.black,
                    fontFamily: 'K2D',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'To create your account please confirm your e-mail address by clicking the link in the e-mail we\'ve just sent you.',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: BColors.black,
                    fontFamily: 'K2D',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 35),
                // Check Verification Button
                AppButton(
                  text: 'Next',
                  onPressed: () async {
                    await _checkEmailVerification(context);
                  },
                ),
                const SizedBox(height: 16),
                // Exit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Clear all caregiver data when exiting
                      try {
                        final caregiverController =
                            Get.find<CaregiverController>();
                        caregiverController.clearAllCaregiverData();
                      } catch (e) {
                        // Controller not found, ignore
                      }

                      try {
                        final regController =
                            Get.find<RegistrationController>();
                        regController.clearAllData();
                      } catch (e) {
                        // Controller not found, ignore
                      }

                      try {
                        final nameController = Get.find<NameController>();
                        nameController.clearAllData();
                      } catch (e) {
                        // Controller not found, ignore
                      }

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Welcomepage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BColors.lightGrey,
                      foregroundColor: BColors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(
                          color: BColors.lightGrey,
                          width: 1,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Exit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'K2D',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Resend email verification text link (exact same as loginpage.dart)
                Center(
                  child: (_resendCooldown == 0)
                      ? (_resendTimer == null
                            // First time
                            ? RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontFamily: 'K2D',
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "To resend email, click ",
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).textTheme.titleSmall!.color,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "here",
                                      style: const TextStyle(
                                        color: BColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'K2D',
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () async {
                                          await _resendEmailVerification(
                                            context,
                                          );
                                        },
                                    ),
                                  ],
                                ),
                              )
                            // After timer finishes
                            : TextButton(
                                onPressed: () async {
                                  await _resendEmailVerification(context);
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  "To resend email, click here",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: BColors.primary,
                                    fontFamily: 'K2D',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ))
                      // During cooldown
                      : Text(
                          "Verification email sent. Resend in ${_resendCooldown}s",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: BColors.black,
                            fontFamily: 'K2D',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
