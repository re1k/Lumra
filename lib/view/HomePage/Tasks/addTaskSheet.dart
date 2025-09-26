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
  final _titleFocus = FocusNode();
  final _titleFieldKey = GlobalKey<FormFieldState<String>>();
  bool _titleTouched = false;

  String? _priority;

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(() => setState(() {}));
    _titleFocus.addListener(() {
      if (!_titleFocus.hasFocus) {
        // user left the field
        setState(() => _titleTouched = true);
        _titleFieldKey.currentState?.validate(); // validate just this field
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit => _titleCtrl.text.trim().isNotEmpty && _priority != null;

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      ///for the sheet with the real device (KEYBOARD)
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
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
              // Title label
              Text('Title', style: BTextTheme.lightTextTheme.titleMedium),

              SizedBox(height: BSizes.xs),

              // Title input
              TextFormField(
                key: _titleFieldKey,
                focusNode: _titleFocus,
                controller: _titleCtrl,
                autovalidateMode: _titleTouched
                    ? AutovalidateMode.always
                    : AutovalidateMode.disabled, // show error after first blur
                decoration: InputDecoration(
                  // hintText: 'e.g., Math assignment', كومنت عشان نوحد بين الفيلدز كنسلت هذي ممكن نرجعها اذا تبونها
                  // filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
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
                textInputAction: TextInputAction.done,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              SizedBox(height: BSizes.spaceBtwinputFields),

              // Priority label
              Text('Priority', style: BTextTheme.lightTextTheme.titleMedium),
              SizedBox(height: BSizes.xs),

              DropdownButtonFormField<String>(
                value: _priority,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
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
                        style: BTextTheme.darkTextTheme.headlineSmall,
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
