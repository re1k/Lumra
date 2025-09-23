import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/view/Account/AccountPage.dart';
import 'package:lumra_project/view/Homepage/ADHDhomePageScreen.dart';




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
      backgroundColor: BColors.primary,
      indicatorColor: BColors.primary.withOpacity(.18),
      labelTextStyle: MaterialStateProperty.all(
        const TextStyle(color: BColors.textwhite),
      ),
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
      selectedIndex: selectedIndex,
      onDestinationSelected: (int value) {
        setState(() {
          selectedIndex = value;
        });

       
        switch (value) {
          case 0:
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => ADHDHomePage()));
            break;
          case 1:
           // Navigator.push(context,
              //  MaterialPageRoute(builder: (context) => ActivityPage()));
            break;
          case 2:
            //Navigator.push(context,
             //   MaterialPageRoute(builder: (context) => CommunityPage()));
            break;
          case 3:
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => AccountPage()));
            break;
        }
      },
    );
  }
}