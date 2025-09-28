import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/view/adhd_registration/widgets/app_button.dart';
import 'package:lumra_project/view/adhd_registration/notification_permission_screen.dart';
import 'package:lumra_project/service/permission_service.dart';
import 'package:lumra_project/view/adhd_registration/onboarding_complete_screen.dart';
import 'package:lumra_project/controller/Registration/caregiver_controller.dart';
import 'package:lumra_project/controller/Registration/registration_controller.dart';
import 'package:lumra_project/controller/Registration/name_controller.dart';

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
                        'assets/images/verified.svg',
                        width: 270,
                        height: 205,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
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
                  onPressed: () async {
                    // Clear all registration data now that verification is complete
                    try {
                      final caregiverController =
                          Get.find<CaregiverController>();
                      caregiverController.clearAllCaregiverData();
                    } catch (e) {
                      // Controller not found, ignore
                    }

                    try {
                      final regController = Get.find<RegistrationController>();
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

                    final granted =
                        await PermissionService.checkNotificationPermission();
                    if (granted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const OnboardingCompleteScreen(),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const NotificationPermissionScreen(),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
