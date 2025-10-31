import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/view/FocusRoom/focusView.dart';
import 'package:lumra_project/model/FocusRoom/FocusRoomModel.dart';
import 'package:lumra_project/controller/FocusRoom/FocusRoomController.dart';
import 'package:get/get.dart';

class FocuspPage extends StatefulWidget {
  const FocuspPage({super.key});

  @override
  State<FocuspPage> createState() => _FocuspPageState();
}

class _FocuspPageState extends State<FocuspPage> {
  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<FocusController>()) {
      Get.put(FocusController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BColors.lightGrey,
      body: const SafeArea(child: FocusView()),
    );
  }
}
