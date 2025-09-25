import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumra_project/model/task/task.dart';
import 'package:lumra_project/controller/task/taskController.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/utils/customWidgets/toastservice.dart';
import 'package:lumra_project/theme/custom_themes/text_theme.dart';

class AddTaskSheet extends StatefulWidget {
  final TaskController controller;
  const AddTaskSheet({super.key, required this.controller});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();

  String? _priority;

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit => _titleCtrl.text.trim().isNotEmpty && _priority != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: BSizes.md,
        right: BSizes.md,
        top: BSizes.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + BSizes.md,
      ),
      child: SingleChildScrollView(
        //REEM ADDED THIS SO FEILDS AS SCROLLABLE WHILE WRITING KEBOARD
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                'Add Task',
                textAlign: TextAlign.center,
                style: BTextTheme.lightTextTheme.headlineLarge,
              ),
              SizedBox(height: BSizes.SpaceBtwItems),

              //Title field
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Math assignment',
                ),
                textInputAction: TextInputAction.done,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),

              SizedBox(height: BSizes.spaceBtwinputFields),

              DropdownButtonFormField<String>(
                value: _priority,
                decoration: InputDecoration(
                  labelText: 'Priority',
                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      BSizes.inputFieldRadius,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      BSizes.inputFieldRadius,
                    ),
                    borderSide: const BorderSide(color: BColors.darkGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      BSizes.inputFieldRadius,
                    ),
                    borderSide: const BorderSide(
                      color: BColors.primary,
                      width: 1.3,
                    ),
                  ),
                ),
                dropdownColor: Colors.white,
                items: const [
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                ],
                onChanged: (v) => setState(() => _priority = v),
                validator: (v) => v == null ? 'Priority is required' : null,
              ),

              SizedBox(height: BSizes.appBarHeight),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSubmit
                      ? () async {
                          if (!_formKey.currentState!.validate()) return;

                          //  at 10 tasks
                          final count = await widget.controller
                              .getTaskCount(); // or getOpenTaskCount()
                          if (count >= 10) {
                            if (!mounted) return;
                            ToastService.error(
                              "You have reached your 10 task limit. Try finishing a task before adding more.",
                            );
                            return;
                          }

                          final newTask = Task(
                            id: '',
                            tasksTitle: _titleCtrl.text.trim(),
                            priority: _priority!,
                            basePriority:
                                _priority!, // keep basePriority in sync
                            isChecked: false,
                            updatedAt: Timestamp.now(),
                          );

                          try {
                            await widget.controller.addTask(newTask);
                            if (!mounted) return;
                            Navigator.pop(context);
                            //  ToastService.success("Task added successfully!");
                          } on FirebaseException catch (e) {
                            if (!mounted) return;
                            ToastService.error("Write error: ${e.code}");
                          }
                        }
                      : null, // disabled 'Add' button
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: Colors.white, // keep icon/text white
                    disabledForegroundColor: Colors.white.withOpacity(0.6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check),
                      const SizedBox(width: 8),
                      Text(
                        "Add",
                        style: BTextTheme
                            .darkTextTheme
                            .headlineSmall, // 👈 same text style
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
