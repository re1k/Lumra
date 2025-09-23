import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';
import 'package:lumra_project/view/Account/AccountPage.dart';
import 'package:lumra_project/view/SplashPage/splashScreen.dart';
import 'package:lumra_project/view/welcomepage.dart';
import 'package:lumra_project/theme/custom_themes/text_field_theme.dart';
import 'package:lumra_project/view/homepage/adhdHomePage.dart';
import 'package:lumra_project/theme/theme.dart';
import 'package:lumra_project/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(AuthController()); // to make it shared (to get the user data)

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lumra Project',
      theme: LumraAppTheme.lightTheme,
      home: SplashGifScreen(
        nextScreen: Welcomepage(),
      ), //splash then we start! :)
      initialRoute: R.home,
      routes: {
        // R.home: (_) => isCaregiver
        //   ? const CaregiverHomePage()    // shows caregiver navbar
        //    : const AdhdHomePage(),        // shows ADHD navbar
        //R.dashboard: (_) => const CaregiverDashboardPage(),
        //R.activity: (_) => const ActivityPage(),
        //R.community: (_) => const CommunityPage(),
        R.account: (_) => const AccountPage(),
      },
    );
  }
}
