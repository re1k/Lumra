import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/Account/UserController.dart';
import '../../theme/base_themes/colors.dart';
import '../../theme/custom_themes/text_theme.dart';
import '../../theme/custom_themes/appbar_theme.dart';
import '../Account/viewProfile.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';
import 'package:lumra_project/view/auth/loginPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Account/QRCode.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final UserController userController;
    if (!Get.isRegistered<UserController>()) {
      userController = Get.put(UserController(FirebaseFirestore.instance));
      userController.init();
    } else {
      userController = Get.find<UserController>();
    }

    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: BColors.light,
      appBar: AppBar(
        title: const Text("Account"),
        backgroundColor: BAppBarTheme.lightAppBarTheme.backgroundColor,
        elevation: BAppBarTheme.lightAppBarTheme.elevation,
        iconTheme: BAppBarTheme.lightAppBarTheme.iconTheme,
        titleTextStyle: BAppBarTheme.lightAppBarTheme.titleTextStyle,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 100,
                backgroundImage:
                
                     const AssetImage('assets/images/Profile_image.jpeg'),
              ),
            ),
            const SizedBox(height: 20),

            // User Name
            Obx(
              () => Text(
                userController.user.value?.name ?? "Loading...",
                style: BTextTheme.lightTextTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 20),

            // Options
            _buildOption(
              icon: Icons.edit,
              text: "Profile Information",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ViewProfile()),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildOption(icon: Icons.article, text: "Posts", onTap: () {}),
            const SizedBox(height: 10),
            _buildOption(
              icon: Icons.bookmark,
              text: "Saved Posts",
              onTap: () {},
            ),
            const SizedBox(height: 10),

            // QR Code Option (only for ADHD)
            Obx(() { 
              if (userController.role.value.toLowerCase() == 'adhd') 
              { return Column( 
                children: 
                [ _buildOption(
                  icon: Icons.qr_code,
                  text: "Generate QR Code For Caregiver",
                  onTap: () {
                 Navigator.push(
                 context,
                 MaterialPageRoute(builder: (context) => const Qrcode()),
                                );
                              },
                            ),
                 const SizedBox(height: 10),
                  ], 
                  ); 
                  } else 
                  { return const SizedBox.shrink(); }
                   }
                   ),

            const SizedBox(height: 30),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await authController.logout();
                  Get.offAll(() => const LoginScreen());
                },
                icon: const Icon(Icons.logout),
                label: const Text("Sign Out"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BColors.primary,
                  foregroundColor: BColors.textwhite,
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 0),
                  textStyle: BTextTheme.lightTextTheme.headlineSmall,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method for building each option row
  Widget _buildOption({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: BColors.iconColor),
      title: Text(text, style: BTextTheme.lightTextTheme.bodySmall),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: BColors.iconColor,
      ),
      onTap: onTap,
    );
  }
}
