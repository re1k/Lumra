import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/view/FocusRoom/focusView.dart';

class FocuspPage extends StatefulWidget {
  const FocuspPage({super.key});

  @override
  State<FocuspPage> createState() => _FocuspPageState();
}

class _FocuspPageState extends State<FocuspPage> {

  @override
  void initState() {
    super.initState();
  }
     @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BColors.lightGrey,
      body: const
      SafeArea(
       child: FocusView(), 
      ),
    );
  }
}
     
