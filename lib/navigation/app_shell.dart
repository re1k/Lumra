import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'nav_config.dart';
import 'nav_controller.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<NavController>(); //

    return Obx(() {
      final r = nav.role.value;
      if (r == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      final items = navConfig[r]!;
      final pages = items.map((e) => e.page).toList();
      final index = nav.currentIndex.value;

      return Scaffold(
        body: IndexedStack(index: index, children: pages),

        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: BColors.primary,
            indicatorColor: BColors.primary.withOpacity(.18),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              return const IconThemeData(color: BColors.textwhite);
            }),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              return const TextStyle(color: BColors.textwhite);
            }),
          ),
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: nav.setTab,
            destinations: [
              for (final i in items)
                NavigationDestination(
                  icon: Icon(i.icon),
                  selectedIcon: Icon(i.icon),
                  label: i.label,
                ),
            ],
          ),
        ),
      );
    });
  }
}
