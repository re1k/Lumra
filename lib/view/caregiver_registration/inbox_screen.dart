import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/controller/Registration/caregiver_controller.dart';
import 'package:lumra_project/view/adhd_registration/widgets/app_button.dart';

class CaregiverInboxScreen extends StatelessWidget {
  const CaregiverInboxScreen({super.key});

  /// Check email verification status
  Future<void> _checkEmailVerification(
    BuildContext context,
    CaregiverController controller,
  ) async {
    await controller.checkEmailVerificationWithNavigation(context);
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
                        await _checkEmailVerification(context, controller);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Exit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          controller.navigateToWelcomePage(context);
                        },
                        style: Theme.of(context).outlinedButtonTheme.style
                            ?.copyWith(
                              backgroundColor: WidgetStateProperty.all(
                                BColors.softGrey,
                              ),
                              foregroundColor: WidgetStateProperty.all(
                                BColors.darkGrey,
                              ),
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
        },
      ),
    );
  }
}
