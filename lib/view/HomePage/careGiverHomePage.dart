import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/task/taskController.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/utils/customWidgets/toastservice.dart';
import 'package:lumra_project/view/Homepage/Calendar/calendarWidgets/openCalendar.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';
import 'package:lumra_project/controller/Account/UserController.dart';
import 'package:lumra_project/view/HomePage/EncouragemenMessage/adhdMessage.dart';
import 'package:lumra_project/view/HomePage/Tasks/tasksView.dart';
import 'package:lumra_project/view/HomePage/Reminders/upcomingReminders.dart';
import 'package:lumra_project/controller/Homepage/Reminders/reminderController.dart';

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

    // Initialize ReminderController
    if (!Get.isRegistered<ReminderController>()) {
      final uid = authContoller.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        Get.put(ReminderController(currentUid: uid));
      }
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
          final name = _userController.user.value?.firstName;
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
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(BSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: BSizes.md),

                // Encouragement banner
                const EncouragementMessage(
                  text:
                      'Write a message you would like you\'re linked Adhd user to read!',
                ),

                SizedBox(height: BSizes.sm),

                // Reminders section
                const UpcomingReminders(),

                Transform.translate(
                  offset: const Offset(0, -8),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      const Icon(Icons.swap_vert, color: BColors.black),
                      const SizedBox(width: 8), // spacing between icon and text
                      Expanded(child: _SectionLabel(text: 'To Do list ')),
                    ],
                  ),
                ),

                // Tasks list - no longer wrapped in Expanded
                TasksList(controller: _taskController),

                SizedBox(height: BSizes.sm),
              ],
            ),
          ),
        ),
      ),

      // FAB+ 10 limitation
      floatingActionButton: FloatingActionButton(
        backgroundColor: BColors.primary,
        foregroundColor: BColors.textwhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BSizes.lg),
        ),
        onPressed: () async {
          final count = await _taskController
              .getActiveTaskCount(); // or getOpenActiveTaskCount()
          if (count >= 10) {
            ToastService.info(
              "You have reached your 10 task limit.",
              " Try finishing a task before adding more.",
            );
            return; // don't open the sheet
          }
          // allowed -> open the add sheet
          TasksList.openAddTaskSheet(context, _taskController);
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: const SizedBox(height: 23),
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
