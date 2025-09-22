import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/view/Homepage/Calendar/calendarWidgets/openCalendar.dart';

class ADHDHomePage extends StatelessWidget implements PreferredSizeWidget {
  const ADHDHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return AppBar(
      backgroundColor: BColors.primary,
      elevation: 0,
      centerTitle: false,
      title: Text(
        'Good Morning',
        style: tt.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: BColors.textwhite,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Open calendar',
          icon: const Icon(Icons.calendar_today, color: BColors.textwhite),
          onPressed: () {
            final authContoller = Get.find<AuthController>();
            openCalendar(currentUid: authContoller.currentUser!.uid);
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(BSizes.appBarHeight);
}
