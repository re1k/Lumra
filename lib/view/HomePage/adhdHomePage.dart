import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumra_project/controller/task/taskController.dart';
import 'package:lumra_project/model/task/task.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/view/navbar_widget.dart';
import 'package:lumra_project/view/Homepage/Calendar/calendarWidgets/openCalendar.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';
import 'package:lumra_project/controller/Account/UserController.dart';
import 'package:lumra_project/view/HomePage/Mood/adhdMood.dart';
import 'package:lumra_project/view/HomePage/EncouragemenMessage/adhdMessage.dart';
import 'package:lumra_project/view/HomePage/Tasks/tasksView.dart';
import 'package:get/get.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TaskController _taskController;
  late final UserController _userController;

  @override
  void initState() {
    super.initState();
    _taskController = TaskController(userId: 'adhdDemo'); // users/adhdDemo
    if (!Get.isRegistered<UserController>()) {
      _userController = Get.put(UserController(FirebaseFirestore.instance));
      _userController.init();
    } else {
      _userController = Get.find<UserController>();
    }
  }

  // Add Task Bottom Sheet
  Future<void> _openAddTaskSheet() async {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    String priority = 'low';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BSizes.borderRadiusLg),
        ),
      ),
      builder: (context) {
        final tt = Theme.of(context).textTheme;
        return Padding(
          padding: EdgeInsets.only(
            left: BSizes.md,
            right: BSizes.md,
            top: BSizes.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + BSizes.md,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Add Task', style: tt.headlineSmall),
                SizedBox(height: BSizes.sm),
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Math assignment',
                  ),
                  textInputAction: TextInputAction.done,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Title is required'
                      : null,
                ),
                SizedBox(height: BSizes.md),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                  ],
                  onChanged: (v) => priority = v ?? 'low',
                ),
                SizedBox(height: BSizes.md),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    // اذا بنسوي طريقة ليان اننا نحط بالمين لون ديفولت أفضل من هذي الطريقة
                    backgroundColor: BColors.primary,
                    foregroundColor: BColors.textwhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(BSizes.buttonRadius),
                    ),
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Add'),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final newTask = Task(
                      id: '',
                      tasksTitle: titleCtrl.text.trim(),
                      priority: priority, //
                      basePriority:
                          priority, // keep the original هذي ممكن نكسنلها في هالفيز
                      isChecked: false,
                      updatedAt: Timestamp.now(),
                    );
                    try {
                      await _taskController.addTask(newTask);
                      if (!mounted) return;
                      Navigator.pop(context);
                    } on FirebaseException catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Write error: ${e.code}')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //  MAIN UI
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: BColors.white, // page background color
      appBar: AppBar(
        backgroundColor: BColors.primary,
        elevation: 0,
        centerTitle: false,
        title: Obx(() {
          final name = _userController.user.value?.name;
          return Text(
            'Good Morning, ${name?.trim().isNotEmpty == true ? name : '...'}',
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
              final authContoller = Get.find<AuthController>();
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

              // Section headers
              Row(
                children: [
                  Expanded(child: _SectionLabel(text: 'To Do list: ')),
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

      // 10-task limit check + brand FAB colors
      floatingActionButton: FloatingActionButton(
        backgroundColor: BColors.primary,
        foregroundColor: BColors.textwhite,
        onPressed: () =>
            TasksList(controller: _taskController).openAddTaskSheet(context),
        child: const Icon(Icons.add),
      ),

      bottomNavigationBar: const NavbarAdhd(),
    );
  }
}

//  small widget
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
