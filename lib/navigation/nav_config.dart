import 'package:flutter/material.dart';
import 'package:lumra_project/view/homepage/adhdHomePage.dart';
import 'package:lumra_project/view/homepage/careGiverHomePage.dart';
import 'package:lumra_project/view/Account/AccountPage.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';

enum UserRole { adhd, caregiver }

class NavItem {
  final String label;
  final IconData icon;
  final Widget page;
  const NavItem({required this.label, required this.icon, required this.page});
}

final Map<UserRole, List<NavItem>> navConfig = {
  UserRole.adhd: [
    NavItem(label: 'Home', icon: Icons.home, page: HomePage()),
    NavItem(
      label: 'Activity',
      icon: Icons.local_activity_rounded,
      page: HomePage(), //Later: replace with ActivityPage()
    ),
    NavItem(
      label: 'Community',
      icon: Icons.people,
      page: HomePage(), //  Later :replace with CommunityPage()
    ),
    NavItem(label: 'Account', icon: Icons.account_box, page: AccountPage()),
  ],

  UserRole.caregiver: [
    NavItem(label: 'Home', icon: Icons.home, page: CareGiverHomePage()),
    NavItem(
      label: 'Dashboard',
      icon: Icons.leaderboard,
      page: HomePage(), //  Later: replace with DashboardPage()
    ),
    NavItem(
      label: 'Community',
      icon: Icons.people,
      page: HomePage(), //  Later: replace with CommunityPage()
    ),
    NavItem(
      label: 'Account',
      icon: Icons.account_box_outlined,
      page: AccountPage(),
    ),
  ],
};
