import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';

class NavbarWidget extends StatefulWidget {
  const NavbarWidget({super.key});

  @override
  State<NavbarWidget> createState() => _NavbarWidgetState();
}

class _NavbarWidgetState extends State<NavbarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      ///check the colors, pull reems theme
      backgroundColor: BColors.primary,
      indicatorColor: BColors.primary.withOpacity(.18),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home, color: BColors.textwhite),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.local_activity, color: BColors.textwhite),
          label: 'Activity',
        ),
        NavigationDestination(
          icon: Icon(Icons.people, color: BColors.textwhite),
          label: 'Community',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_box_outlined, color: BColors.textwhite),
          label: 'Account',
        ),
      ],
      onDestinationSelected: (int value) {
        setState(() {
          selectedIndex = value;
        });
      },
      selectedIndex: selectedIndex,
    );
  }
}
