//WE DON'T NEED THIS CLASS, BUT KEEP IT AS A BACKUP
// import 'package:flutter/material.dart';
// import 'package:lumra_project/theme/base_themes/colors.dart';
// import 'package:lumra_project/routes.dart';

// class NavbarAdhd extends StatefulWidget {
//   final int selectedIndex;
//   const NavbarAdhd({super.key, this.selectedIndex = 0});

//   @override
//   State<NavbarAdhd> createState() => _NavbarAdhdState();
// }

// class _NavbarAdhdState extends State<NavbarAdhd> {
//   late int _index;

//   @override
//   void initState() {
//     super.initState();
//     _index = widget.selectedIndex;
//   }

//   void _go(int i) {
//     setState(() => _index = i);
//     switch (i) {
//       case 0:
//         Navigator.pushReplacementNamed(context, R.home);
//         break;
//       case 1:
//         //   Navigator.pushReplacementNamed(context, R.activity);
//         break;
//       case 2:
//         //   Navigator.pushReplacementNamed(context, R.community);
//         break;
//       case 3:
//         Navigator.pushReplacementNamed(context, R.account);
//         break;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return NavigationBar(
//       backgroundColor: BColors.primary,
//       indicatorColor: BColors.primary.withOpacity(.18),
//       labelTextStyle: MaterialStateProperty.all(
//         const TextStyle(color: BColors.textwhite),
//       ),
//       destinations: const [
//         NavigationDestination(
//           icon: Icon(Icons.home, color: BColors.textwhite),
//           label: 'Home',
//         ),
//         NavigationDestination(
//           icon: Icon(Icons.local_activity_rounded, color: BColors.textwhite),
//           label: 'Activity',
//         ),
//         NavigationDestination(
//           icon: Icon(Icons.people, color: BColors.textwhite),
//           label: 'Community',
//         ),
//         NavigationDestination(
//           icon: Icon(Icons.account_box, color: BColors.textwhite),
//           /////هنا الايكون غير عن الكيرقيفر شوفو وش احلى ونعتمدها لهم الاثنين
//           label: 'Account',
//         ),
//       ],
//       selectedIndex: _index,
//       onDestinationSelected: _go,
//     );
//   }
// }

// class NavbarCaregiver extends StatefulWidget {
//   final int selectedIndex;
//   const NavbarCaregiver({super.key, this.selectedIndex = 0});

//   @override
//   State<NavbarCaregiver> createState() => _NavbarCaregiverState();
// }

// class _NavbarCaregiverState extends State<NavbarCaregiver> {
//   late int _index;

//   @override
//   void initState() {
//     super.initState();
//     _index = widget.selectedIndex;
//   }

//   void _go(int i) {
//     setState(() => _index = i);
//     switch (i) {
//       case 0:
//         Navigator.pushReplacementNamed(context, R.home);
//         break;
//       case 1:
//         // Navigator.pushReplacementNamed(context, R.dashboard);
//         break;
//       case 2:
//         // Navigator.pushReplacementNamed(context, R.community);
//         break;
//       case 3:
//         Navigator.pushReplacementNamed(context, R.account);
//         break;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return NavigationBar(
//       backgroundColor: BColors.primary,
//       indicatorColor: BColors.primary.withOpacity(.18),
//       labelTextStyle: MaterialStateProperty.all(
//         const TextStyle(color: BColors.textwhite),
//       ),
//       destinations: const [
//         NavigationDestination(
//           icon: Icon(Icons.home, color: BColors.textwhite),
//           label: 'Home',
//         ),
//         NavigationDestination(
//           icon: Icon(Icons.leaderboard, color: BColors.textwhite),
//           label: 'Dashboard',
//         ),
//         NavigationDestination(
//           icon: Icon(Icons.people, color: BColors.textwhite),
//           label: 'Community',
//         ),
//         NavigationDestination(
//           icon: Icon(Icons.account_box_outlined, color: BColors.textwhite),
//           label: 'Account',
//         ),
//       ],
//       selectedIndex: _index,
//       onDestinationSelected: _go,
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:lumra_project/theme/base_themes/colors.dart';

// import 'package:lumra_project/view/homepage/adhdHomePage.dart';
// import 'package:lumra_project/view/Account/AccountPage.dart';
// // import 'package:lumra_project/view/Activity/ActivityPage.dart';
// // import 'package:lumra_project/view/Community/CommunityPage.dart';

// class NavbarAdhd extends StatefulWidget {
//   final int selectedIndex;
//   const NavbarAdhd({super.key, this.selectedIndex = 0});

//   @override
//   State<NavbarAdhd> createState() => _NavbarAdhdState();
// }

// class _NavbarAdhdState extends State<NavbarAdhd> {
//   late int _selected; // highlighted tab
//   late int _pageIndex; // index in _pages

//   final _pages = const <Widget>[HomePage(), AccountPage()];
//   final _tabToPage = <int>[0, -1, -1, 1]; // Activity/Community => coming soon

//   @override
//   void initState() {
//     super.initState();
//     // clamp selected tab to [0, 3]
//     _selected = (widget.selectedIndex.clamp(0, _tabToPage.length - 1)) as int;
//     final p = _tabToPage[_selected];
//     _pageIndex = (p == -1) ? 0 : p; // fallback to Home if tab isn't ready
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: IndexedStack(index: _pageIndex, children: _pages),
//       bottomNavigationBar: NavigationBar(
//         backgroundColor: BColors.primary,
//         indicatorColor: BColors.primary.withOpacity(.18),
//         labelTextStyle: MaterialStateProperty.all(
//           const TextStyle(color: BColors.textwhite),
//         ),
//         destinations: const [
//           NavigationDestination(
//             icon: Icon(Icons.home, color: BColors.textwhite),
//             label: 'Home',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.local_activity_rounded, color: BColors.textwhite),
//             label: 'Activity',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.people, color: BColors.textwhite),
//             label: 'Community',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.account_box, color: BColors.textwhite),
//             label: 'Account',
//           ),
//         ],
//         selectedIndex: _selected,
//         onDestinationSelected: (i) {
//           setState(() {
//             _selected = i;
//             final p = _tabToPage[i];
//             if (p == -1) {
//               ScaffoldMessenger.of(
//                 context,
//               ).showSnackBar(const SnackBar(content: Text('Coming soon')));
//             } else {
//               _pageIndex = p; // 0 = Home, 1 = Account
//             }
//           });
//         },
//       ),
//     );
//   }
// }

// class NavbarCaregiver extends StatefulWidget {
//   final int selectedIndex;
//   const NavbarCaregiver({super.key, this.selectedIndex = 0});

//   @override
//   State<NavbarCaregiver> createState() => _NavbarCaregiverState();
// }

// class _NavbarCaregiverState extends State<NavbarCaregiver> {
//   late int _selected; // highlighted tab
//   late int _pageIndex; // index in _pages

//   final _pages = const <Widget>[HomePage(), AccountPage()];
//   final _tabToPage = <int>[0, -1, -1, 1]; //

//   @override
//   void initState() {
//     super.initState();
//     _selected = widget.selectedIndex;
//     _pageIndex = 0; // start on Home
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: IndexedStack(index: _pageIndex, children: _pages),
//       bottomNavigationBar: NavigationBar(
//         backgroundColor: BColors.primary,
//         indicatorColor: BColors.primary.withOpacity(.18),
//         labelTextStyle: MaterialStateProperty.all(
//           const TextStyle(color: BColors.textwhite),
//         ),
//         destinations: const [
//           NavigationDestination(
//             icon: Icon(Icons.home, color: BColors.textwhite),
//             label: 'Home',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.leaderboard, color: BColors.textwhite),
//             label: 'Dashboard',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.people, color: BColors.textwhite),
//             label: 'Community',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.account_box_outlined, color: BColors.textwhite),
//             label: 'Account',
//           ),
//         ],
//         selectedIndex: _selected,
//         onDestinationSelected: (i) {
//           setState(() {
//             _selected = i; //  tapped tab
//             final p = _tabToPage[i];
//             if (p == -1) {
//               ScaffoldMessenger.of(
//                 context,
//               ).showSnackBar(SnackBar(content: Text('Coming soon')));
//             } else {
//               _pageIndex = p; // show Home(0) or Account(1)
//             }
//           });
//         },
//       ),
//     );
//   }
// }
