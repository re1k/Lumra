import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/controller/Registration/registration_flow_controller.dart';
import 'package:lumra_project/view/adhd_registration/widgets/app_button.dart';
import 'package:lumra_project/view/adhd_registration/verified_screen.dart';
import 'dart:async';

class VerificationWaitingScreen extends StatefulWidget {
  const VerificationWaitingScreen({super.key});

  @override
  State<VerificationWaitingScreen> createState() =>
      _VerificationWaitingScreenState();
}

class _VerificationWaitingScreenState extends State<VerificationWaitingScreen> {
  Timer? _resendTimer;
  int _resendCooldown = 0;
  bool _isResendDisabled = false;

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown() {
    _isResendDisabled = true;
    _resendCooldown = 60; // 1 minute in seconds

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() {
          _resendCooldown--;
        });
      } else {
        setState(() {
          _isResendDisabled = false;
        });
        timer.cancel();
      }
    });
  }

  /// Check email verification status
  Future<void> _checkEmailVerification(BuildContext context) async {
    final controller = Get.find<RegistrationFlowController>();

    try {
      final isVerified = await controller.checkEmailVerification();

      if (isVerified) {
        // Email is verified - save user data and navigate to next step
        try {
          final success = await controller.saveUserDataAfterVerification();
          if (success && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VerifiedScreen()),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to save user data. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Email Not Verified'),
          content: const Text('You have not verified your email yet.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Resend email verification
  Future<void> _resendEmailVerification(BuildContext context) async {
    final controller = Get.find<RegistrationFlowController>();

    try {
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // SVG Image
              Center(
                child: SvgPicture.asset(
                  'assets/images/checkinbox.svg',
                  width: 270,
                  height: 200,
                ),
              ),
              const SizedBox(height: 32),
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
              const SizedBox(height: 40),
              // Check Verification Button
              AppButton(
                text: 'Check Verification',
                onPressed: () async {
                  await _checkEmailVerification(context);
                },
              ),
              const SizedBox(height: 16),
              // Resend Verification Email Button
              AppButton(
                text: _isResendDisabled
                    ? 'Resend verification email'
                    : 'Resend verification email',
                enabled: !_isResendDisabled,
                onPressed: _isResendDisabled
                    ? null
                    : () async {
                        await _resendEmailVerification(context);
                      },
              ),
              // Show cooldown message when disabled
              if (_isResendDisabled) ...[
                const SizedBox(height: 8),
                Text(
                  'To resend, please wait 1 minute.',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: BColors.darkGrey,
                    fontFamily: 'K2D',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
