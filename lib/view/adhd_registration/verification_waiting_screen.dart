import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/controller/Registration/registration_flow_controller.dart';
import 'package:lumra_project/view/adhd_registration/widgets/app_button.dart';
import 'package:lumra_project/view/adhd_registration/notification_permission_screen.dart';
import 'package:lumra_project/view/adhd_registration/onboarding_complete_screen.dart';
import 'package:lumra_project/service/permission_service.dart';
import 'package:lumra_project/view/welcomePage.dart';
import 'package:lumra_project/utils/customWidgets/custom_dialog.dart';
import 'dart:async';

class VerificationWaitingScreen extends StatefulWidget {
  const VerificationWaitingScreen({super.key});

  @override
  State<VerificationWaitingScreen> createState() =>
      _VerificationWaitingScreenState();
}

class _VerificationWaitingScreenState extends State<VerificationWaitingScreen> {
  int _resendCooldown = 0;
  Timer? _resendTimer;
  TapGestureRecognizer? _tapGestureRecognizer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _tapGestureRecognizer?.dispose();
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
    final controller = Get.find<RegistrationFlowController>();

    try {
      final isVerified = await controller.checkEmailVerification();

      if (isVerified) {
        // Email is verified - navigate directly to notification/onboarding
        if (context.mounted) {
          final granted = await PermissionService.checkNotificationPermission();
          if (granted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const OnboardingCompleteScreen(),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationPermissionScreen(),
              ),
            );
          }
        }
      } else {
        // Email is not verified - show popup dialog
        if (context.mounted) {
          _showVerificationDialog(context);
        }
      }
    } catch (e) {
      // Handle any errors
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

  /// Show verification dialog when email is not verified
  void _showVerificationDialog(BuildContext context) {
    CustomDialog.showCloseOnly(
      context,
      title: 'Email Not Verified',
      message:
          'You have not verified your email yet. Please check your inbox and click the verification link we sent you.',
    );
  }

  /// Resend email verification
  Future<void> _resendEmailVerification(BuildContext context) async {
    final controller = Get.find<RegistrationFlowController>();

    try {
      await controller.resendVerificationEmail();
      if (context.mounted) {
        // No popup and no snackbar for successful send
        // Start cooldown after successful send
        _startResendCooldown();
      }
    } catch (e) {
      if (context.mounted) {
        // Only show error popup for real failures, not warnings
        final errorMessage = e.toString().replaceFirst('Exception: ', '');

        // Check if it's a real error (not just a warning)
        if (!errorMessage.toLowerCase().contains('ignoring header') &&
            !errorMessage.toLowerCase().contains('firebase-locale') &&
            !errorMessage.toLowerCase().contains('null')) {
          // Check for specific Firebase error codes
          if (errorMessage.toLowerCase().contains('too-many-requests') ||
              errorMessage.toLowerCase().contains('too many requests')) {
            CustomDialog.showError(
              context,
              message:
                  'Too many attempts. Please wait a few minutes before trying again.',
              title: 'Try again later',
            );
          } else {
            CustomDialog.showError(
              context,
              message: 'Try again later',
              title: '',
            );
          }
        }
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
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    64,
              ),
              child: Transform.translate(
                offset: const Offset(0, -25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // SVG Image (slightly down-left)
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
                                    recognizer: _tapGestureRecognizer ??=
                                        TapGestureRecognizer()
                                          ..onTap = () async {
                                            await _resendEmailVerification(
                                              context,
                                            );
                                          },
                                  ),
                                ],
                              ),
                            )
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
        ),
      ),
    );
  }
}
