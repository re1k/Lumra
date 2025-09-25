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
      page: ComingSoonPage(
        feature: 'Activity',
      ), //Later: replace with ActivityPage()
    ),
    NavItem(
      label: 'Community',
      icon: Icons.people,
      page: ComingSoonPage(
        feature: 'Activity',
      ), //  Later :replace with CommunityPage()
    ),
    NavItem(label: 'Account', icon: Icons.account_box, page: AccountPage()),
  ],

  UserRole.caregiver: [
    NavItem(label: 'Home', icon: Icons.home, page: CareGiverHomePage()),
    NavItem(
      label: 'Dashboard',
      icon: Icons.leaderboard,
      page: ComingSoonPage(
        feature: 'Dashboard',
      ), //  Later: replace with DashboardPage()
    ),
    NavItem(
      label: 'Community',
      icon: Icons.people,
      page: ComingSoonPage(
        feature: 'Community',
      ), //  Later: replace with CommunityPage()
    ),
    NavItem(
      label: 'Account',
      icon: Icons.account_box_outlined,
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
