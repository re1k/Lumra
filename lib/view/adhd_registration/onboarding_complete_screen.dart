import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/view/adhd_registration/widgets/app_button.dart';
import 'package:lumra_project/navigation/role_aware_root.dart';
import 'package:get/get.dart';

class OnboardingCompleteScreen extends StatelessWidget {
  const OnboardingCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Transform.translate(
            offset: const Offset(0, -25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              // Success Icon
              SizedBox(
                width: double.infinity,
                child: Align(
                  alignment: const Alignment(0, 0.0),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: SvgPicture.asset(
                      'assets/images/Successful.svg',
                      width: 270,
                      height: 205,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'We\'re all set!',
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
                'Let\'s get started on your journey',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: BColors.black,
                  fontFamily: 'K2D',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Button at bottom
              AppButton(
                text: 'Get Started',
                onPressed: () {
                  Get.offAll(() => RoleAwareRoot());
                },
              ),
              const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
