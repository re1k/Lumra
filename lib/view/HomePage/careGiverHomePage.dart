import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import 'package:lumra_project/controller/task/taskController.dart';
import 'package:lumra_project/model/task/task.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/utils/customWidgets/toastservice.dart';
// import 'package:lumra_project/view/navbar_widget.dart'; // handled by AppShell
import 'package:lumra_project/view/Homepage/Calendar/calendarWidgets/openCalendar.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';
import 'package:lumra_project/controller/Account/UserController.dart';
import 'package:lumra_project/view/HomePage/Mood/adhdMood.dart';
import 'package:lumra_project/view/HomePage/EncouragemenMessage/adhdMessage.dart';
import 'package:lumra_project/view/HomePage/Tasks/tasksView.dart';

class CareGiverHomePage extends StatefulWidget {
  const CareGiverHomePage({super.key});

  @override
  State<CareGiverHomePage> createState() => _CareGiverHomePageState();
}

class _CareGiverHomePageState extends State<CareGiverHomePage> {
  late final TaskController _taskController;
  late final UserController _userController;
  final authContoller = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _taskController = TaskController(userId: authContoller.currentUser!.uid);
    if (!Get.isRegistered<UserController>()) {
      _userController = Get.put(UserController(FirebaseFirestore.instance));
      _userController.init();
    } else {
      _userController = Get.find<UserController>();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: BColors.white,
      appBar: AppBar(
        backgroundColor: BColors.primary,
        elevation: 0,
        centerTitle: false,
        title: Obx(() {
          final name = _userController.user.value?.name;
          return Text(
            'Hello, ${name?.trim().isNotEmpty == true ? name : '...'}',
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: BColors.textwhite,
            ),
          );
        }),
        actions: [
          IconButton(
            tooltip: 'Open calendar',
            icon: const Icon(Icons.calendar_today, color: BColors.textwhite),
            onPressed: () {
              openCalendar(currentUid: authContoller.currentUser!.uid);
            },
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(BSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "How’s your mood today?",
                style: tt.titleLarge?.copyWith(
                  fontSize: BSizes.lg,
                  color: BColors.black,
                ),
              ),

              const MoodRow(),

              SizedBox(height: BSizes.md),

              // Encouragement banner
              const EncouragementMessage(),

              SizedBox(height: BSizes.sm),

              Row(
                children: [
                  const Expanded(child: _SectionLabel(text: 'To Do list: ')),
                  SizedBox(width: BSizes.sm),
                ],
              ),

              SizedBox(height: BSizes.xs),

              // Tasks list
              Expanded(child: TasksList(controller: _taskController)),

              SizedBox(height: BSizes.sm),
            ],
          ),
        ),
      ),

      // FAB+ 10 limitation
      floatingActionButton: FloatingActionButton(
        backgroundColor: BColors.primary,
        foregroundColor: BColors.textwhite,
        onPressed: () async {
          final count = await _taskController
              .getActiveTaskCount(); // or getOpenActiveTaskCount()
          if (count >= 10) {
            ToastService.error(
              "You have reached your 10 task limit. Try finishing a task before adding more.",
            );
            return; // don't open the sheet
          }
          // allowed -> open the add sheet
          TasksList(controller: _taskController).openAddTaskSheet(context);
        },
        child: const Icon(Icons.add),
      ),

      // bottomNavigationBar: const NavbarAdhd(), // handled by AppShell
    );
  }
}

// small widget
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: BSizes.sm, vertical: BSizes.xs),
      decoration: BoxDecoration(
        color: BColors.white,
        borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
        border: Border.all(color: Colors.transparent),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: BColors.texBlack,
        ),
      ),
    );
  }
}
