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
import "package:lumra_project/view/ChatBootADHD/ChatBotWidget.dart";
import 'package:lumra_project/view/Homepage/EncouragemenMessage/caregiverMessage.dart';

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
      backgroundColor: BColors.lightGrey,
      body: SafeArea(
        child: Stack(
          children: [
            // Main scrollable content
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  BSizes.lg,
                  BSizes.lg,
                  BSizes.lg,
                  BSizes.lg + 100, // Extra bottom padding for navbar
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // header with greeting
                    Obx(() {
                      final name = _userController.user.value?.firstName;
                      return Container(
                        padding: EdgeInsets.only(bottom: BSizes.lg),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hi, ${name?.trim().isNotEmpty == true ? name : '...'}',
                                    style: tt.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: BColors.black,
                                      fontSize: 28,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  SizedBox(height: BSizes.xs),
                                  Text(
                                    'Let’s check in on your ADHD user',
                                    style: tt.bodyLarge?.copyWith(
                                      color: BColors.darkGrey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: BSizes.md),
                            Container(
                              decoration: BoxDecoration(
                                color: BColors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                tooltip: 'Open calendar',
                                icon: const Icon(
                                  Icons.calendar_today,
                                  color: BColors.primary,
                                ),
                                onPressed: () {
                                  openCalendar(
                                    currentUid: authContoller.currentUser!.uid,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Encouragement banner
                    const RealStickerEnvelope(),

                    SizedBox(height: BSizes.lg),

                    // Reminders section
                    const UpcomingReminders(),

                    SizedBox(height: BSizes.lg),

                    // To-Do List section with integrated + icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'To-Do List',
                          style: tt.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: BColors.black,
                            fontSize: 20,
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final count = await _taskController
                                .getActiveTaskCount();
                            if (count >= 10) {
                              ToastService.info(
                                "You have reached your 10 task limit.",
                                " Try finishing a task before adding more.",
                              );
                              return;
                            }
                            TasksList.openAddTaskSheet(
                              context,
                              _taskController,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: const Icon(
                              Icons.add,
                              size: 20,
                              color: BColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: BSizes.md),

                    // Tasks list
                    TasksList(controller: _taskController),
                  ],
                ),
              ),
            ),
            //  Overlay the chatbot on top of the pages
            const ChatBotWidget(role: 'caregiver'),
          ],
        ),
      ),
    );
  }
}
