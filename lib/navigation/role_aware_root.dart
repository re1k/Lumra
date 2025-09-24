import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lumra_project/navigation/app_shell.dart';
import 'package:lumra_project/navigation/nav_controller.dart';
import 'package:lumra_project/navigation/nav_config.dart';

import 'package:lumra_project/controller/Account/UserController.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';

class RoleAwareRoot extends StatelessWidget {
  RoleAwareRoot({super.key}) {
    if (!Get.isRegistered<UserController>()) {
      final uc = Get.put(UserController(FirebaseFirestore.instance));
      uc.init();
    }
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(Get.find<AuthController>());
    }
    if (!Get.isRegistered<NavController>()) {
      Get.put(NavController(), permanent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();
    final nav = Get.find<NavController>();

    return Obx(() {
      final u = userController.user.value;
      if (u == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      final roleStr = (u.role).toString().toLowerCase().trim();
      final role = roleStr == 'caregiver' ? UserRole.caregiver : UserRole.adhd;
      nav.setRole(role);

      return const AppShell();
    });
  }
}
