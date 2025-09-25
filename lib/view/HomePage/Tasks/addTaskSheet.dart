// lib/view/HomePage/Tasks/add_task_sheet.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumra_project/model/task/task.dart';
import 'package:lumra_project/controller/task/taskController.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/theme/base_themes/text_strings.dart';

class AddTaskSheet extends StatefulWidget {
  final TaskController controller;
  const AddTaskSheet({super.key, required this.controller});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  String _priority = 'low';

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,

                children: [
                  Text(
                    'Add Task',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: BColors.texBlack,
                    ),
                  ),
                ],
              ),
              SizedBox(height: BSizes.SpaceBtwItems),
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
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                ],
                onChanged: (v) => _priority = v ?? 'low',
              ),

              SizedBox(height: BSizes.SpaceBtwSections),

              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: BColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.check),
                label: const Text(
                  'Add',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  //In case someone bypasses the FAB (if we reuse AddTaskSheet elsewhere)
                  final count = await widget.controller.getTaskCount();
                  if (count >= 10) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task limit reached (10).')),
                    );
                    return;
                  }

                  final newTask = Task(
                    id: '',
                    tasksTitle: _titleCtrl.text.trim(),
                    priority: _priority,
                    basePriority: _priority,
                    isChecked: false,
                    updatedAt: Timestamp.now(),
                  );

                  try {
                    await widget.controller.addTask(newTask);
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
      ),
    );
  }
}
