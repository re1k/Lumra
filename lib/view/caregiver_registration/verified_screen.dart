import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/view/adhd_registration/widgets/app_button.dart';
import 'package:lumra_project/view/adhd_registration/notification_permission_screen.dart';

class CaregiverVerifiedScreen extends StatelessWidget {
  const CaregiverVerifiedScreen({super.key});

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
              // Success Icon
              Center(
                child: SvgPicture.asset(
                  'assets/images/verified.svg',
                  width: 270,
                  height: 200,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Your caregiver account is verified!',
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
                'You\'re all set to support your child',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: BColors.black,
                  fontFamily: 'K2D',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              AppButton(
                text: 'Next',
                onPressed: () {
                  // Navigate to notification permission screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const NotificationPermissionScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
