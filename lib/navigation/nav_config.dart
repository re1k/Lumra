import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:lumra_project/controller/Activity/ActivityController.dart';
import 'package:lumra_project/view/Activity/activityView.dart';
import 'package:lumra_project/view/Community/CommunityPage.dart';
import 'package:lumra_project/view/FocusRoom/focusPage.dart';
import 'package:lumra_project/view/homepage/adhdHomePage.dart';
import 'package:lumra_project/view/homepage/careGiverHomePage.dart';
import 'package:lumra_project/view/Account/AccountPage.dart';

enum UserRole { adhd, caregiver }

class NavItem {
  final String label;
  final IconData icon;
  final Widget page;
  final VoidCallback? onTap;
  const NavItem({
    required this.label,
    required this.icon,
    required this.page,
    this.onTap,
  });
}

final Map<UserRole, List<NavItem>> navConfig = {
  UserRole.adhd: [
    NavItem(label: 'Home', icon: Icons.home_rounded, page: HomePage()),
    NavItem(
      label: 'Activities',
      icon: Icons.local_activity_rounded,
      page: ActivityView(),
    ),
    NavItem(label: 'Focus', icon: Icons.timer, page: FocuspPage()),
    NavItem(
      label: 'Community',
      icon: Icons.people_alt_rounded,
      page: CommunityPage(),
    ),
    NavItem(
      label: 'Account',
      icon: Icons.account_circle_rounded,
      page: AccountPage(),
    ),
  ],

  UserRole.caregiver: [
    NavItem(label: 'Home', icon: Icons.home_rounded, page: CareGiverHomePage()),
    NavItem(
      label: 'Dashboard',
      icon: Icons.leaderboard_rounded,
      page: ComingSoonPage(
        feature: 'Dashboard',
      ), //  Later: replace with DashboardPage()
    ),
    NavItem(
      label: 'Community',
      icon: Icons.people_alt_rounded,
      page: CommunityPage(),
    ),
    NavItem(
      label: 'Account',
      icon: Icons.account_circle_rounded,
      page: AccountPage(),
    ),
  ],
};

//this class will be deleted later
class ComingSoonPage extends StatelessWidget {
  final String feature;
  const ComingSoonPage({required this.feature, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          '$feature will be available soon!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
