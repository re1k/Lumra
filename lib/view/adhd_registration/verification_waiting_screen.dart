import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/controller/Registration/registration_flow_controller.dart';
import 'package:lumra_project/view/adhd_registration/widgets/app_button.dart';
import 'package:lumra_project/view/adhd_registration/verified_screen.dart';
import 'package:lumra_project/view/welcomePage.dart';

class VerificationWaitingScreen extends StatelessWidget {
  const VerificationWaitingScreen({super.key});

  /// Check email verification status
  Future<void> _checkEmailVerification(BuildContext context) async {
    final controller = Get.find<RegistrationFlowController>();

    try {
      final isVerified = await controller.checkEmailVerification();

      if (isVerified) {
        // Email is verified - navigate to next step
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VerifiedScreen()),
          );
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
          content: const Text('Your account has not been verified yet.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await _resendEmailVerification(context);
              },
              child: const Text('Resend Email'),
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
                'Please confirm your e-mail address by clicking the link in the e-mail we\'ve just sent you.',
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
              // Exit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Welcomepage(),
                      ),
                      (route) => false,
                    );
                  },
                  style: Theme.of(context).outlinedButtonTheme.style?.copyWith(
                    backgroundColor: WidgetStateProperty.all(BColors.softGrey),
                    foregroundColor: WidgetStateProperty.all(BColors.darkGrey),
                  ),
                  child: Text(
                    'Exit',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: BColors.white,
                      fontFamily: 'K2D',
                    ).copyWith(color: BColors.darkGrey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
