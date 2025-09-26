import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/controller/Registration/caregiver_controller.dart';
import 'package:lumra_project/view/adhd_registration/widgets/app_button.dart';
import 'dart:async';

class CaregiverInboxScreen extends StatefulWidget {
  const CaregiverInboxScreen({super.key});

  @override
  State<CaregiverInboxScreen> createState() => _CaregiverInboxScreenState();
}

class _CaregiverInboxScreenState extends State<CaregiverInboxScreen> {
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
  Future<void> _checkEmailVerification(
    BuildContext context,
    CaregiverController controller,
  ) async {
    await controller.checkEmailVerificationWithNavigation(context);
  }

  /// Resend email verification
  Future<void> _resendEmailVerification(
    BuildContext context,
    CaregiverController controller,
  ) async {
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
    return ChangeNotifierProvider(
      create: (context) => CaregiverController(),
      child: Consumer<CaregiverController>(
        builder: (context, controller, child) {
          return Scaffold(
            backgroundColor: BColors.white,
            appBar: AppBar(backgroundColor: BColors.white),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
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
                      'To create your account please confirm your e-mail address by clicking the link in the e-mail we\'ve just sent you..',
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
                        await _checkEmailVerification(context, controller);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Resend Verification Email Button
                    AppButton(
                      text: 'Resend verification email',
                      enabled: !_isResendDisabled,
                      onPressed: _isResendDisabled
                          ? null
                          : () async {
                              await _resendEmailVerification(
                                context,
                                controller,
                              );
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
        },
      ),
    );
  }
}
