import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart' as theme;

class CategoryStyle {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  const CategoryStyle({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}

class CategoryStyles {
  static CategoryStyle byKey(String? key) {
    final k = (key ?? '').trim().toLowerCase();
    if (k == 'mindfulness') {
      return CategoryStyle(
        icon: Icons.self_improvement_rounded,
        iconColor: Color.fromARGB(255, 111, 174, 190),
        bgColor: const Color(0xFFCDF0F9).withOpacity(0.32),
      );
    }
    if (k == 'creative') {
      return CategoryStyle(
        icon: Icons.brush_rounded,
        iconColor: Color(0xFFE9B8A9),
        bgColor: const Color(0xFFE9B8A9).withOpacity(0.32),
      );
    }
    if (k == 'sport') {
      return CategoryStyle(
        icon: Icons.directions_run_rounded,
        iconColor: Color.fromARGB(255, 222, 187, 136),
        bgColor: const Color(0xFFFDE8C9).withOpacity(0.32),
      );
    }

    if (k == 'learning') {
      return CategoryStyle(
        icon: Icons.menu_book_rounded,
        iconColor: Color.fromARGB(255, 87, 185, 218),
        bgColor: Color.fromARGB(255, 87, 185, 218).withOpacity(0.32),
      );
    }
    return CategoryStyle(
      icon: Icons.local_activity_rounded,
      iconColor: theme.BColors.iconColor,
      bgColor: theme.BColors.lightContainer,
    );
  }
}
