import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumra_project/model/task/task.dart';
import 'package:lumra_project/controller/task/taskController.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/utils/customWidgets/toastservice.dart';
import 'package:lumra_project/theme/custom_themes/text_theme.dart';

class AddTaskSheet extends StatefulWidget {
  final TaskController controller;
  final Task? taskToEdit;

  const AddTaskSheet({super.key, required this.controller, this.taskToEdit});

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

    // Pre-fill form if editing
    if (widget.taskToEdit != null) {
      _titleCtrl.text = widget.taskToEdit!.tasksTitle;
      _priority = widget.taskToEdit!.priority;
    }

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
    final maxHeight = MediaQuery.of(context).size.height * 0.7;

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          left: BSizes.md,
          right: BSizes.md,
          bottom: MediaQuery.of(
            context,
          ).viewInsets.bottom, // shifts for keyboard
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: CustomScrollView(
            slivers: [
              // Pinned title
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedHeaderDelegate(
                  child: Center(
                    child: Text(
                      widget.taskToEdit != null ? "Edit Task" : "Add Task",
                      style: BTextTheme.lightTextTheme.headlineLarge,
                    ),
                  ),
                ),
              ),

              // Scrollable body
              SliverFillRemaining(
                hasScrollBody: true,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Title",
                          style: BTextTheme.lightTextTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          focusNode: _titleFocus,
                          controller: _titleCtrl,
                          autovalidateMode: _titleTouched
                              ? AutovalidateMode.always
                              : AutovalidateMode
                                    .disabled, // show error after first blur
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? "Title is required"
                              : null,
                          style: Theme.of(context).textTheme.bodyLarge,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                BSizes.inputFieldRadius,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          "Priority",
                          style: BTextTheme.lightTextTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _priority,
                          items: const [
                            DropdownMenuItem(
                              value: "high",
                              child: Text("High"),
                            ),
                            DropdownMenuItem(
                              value: "medium",
                              child: Text("Medium"),
                            ),
                            DropdownMenuItem(value: "low", child: Text("Low")),
                          ],
                          onChanged: (v) => setState(() => _priority = v),
                          validator: (v) =>
                              v == null ? "Priority is required" : null,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                BSizes.inputFieldRadius,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: BSizes.SpaceBtwItems),

                        SizedBox(height: BSizes.appBarHeight),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _canSubmit
                                ? () async {
                                    if (!_formKey.currentState!.validate())
                                      return;

                                    //  at 10 tasks
                                    final count = await widget.controller
                                        .getTaskCount(); // or getOpenTaskCount()
                                    if (count >= 10) {
                                      if (!mounted) return;
                                      ToastService.show(
                                        "You have reached your 10 task limit.",
                                        " Try finishing a task before adding more.",
                                      );

                                      return;
                                    }

                                    if (widget.taskToEdit != null) {
                                      // Update existing task
                                      final updatedTask = Task(
                                        id: widget.taskToEdit!.id,
                                        tasksTitle: _titleCtrl.text.trim(),
                                        priority: _priority!,
                                        basePriority: _priority!,
                                        isChecked: widget.taskToEdit!.isChecked,
                                        updatedAt: Timestamp.now(),
                                      );

                                      try {
                                        await widget.controller.updateTask(
                                          updatedTask,
                                        );
                                        if (!mounted) return;
                                        Navigator.pop(context);
                                      } on FirebaseException catch (e) {
                                        if (!mounted) return;
                                        ToastService.error(
                                          "Update error: ${e.code}",
                                        );
                                      }
                                    } else {
                                      // Add new task
                                      final newTask = Task(
                                        id: '',
                                        tasksTitle: _titleCtrl.text.trim(),
                                        priority: _priority!,
                                        basePriority: _priority!,
                                        isChecked: false,
                                        updatedAt: Timestamp.now(),
                                      );

                                      try {
                                        await widget.controller.addTask(
                                          newTask,
                                        );
                                        if (!mounted) return;
                                        Navigator.pop(context);
                                      } on FirebaseException catch (e) {
                                        if (!mounted) return;
                                        ToastService.error(
                                          "Write error: ${e.code}",
                                        );
                                      }
                                    }
                                  }
                                : null, // disabled 'Add' button
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              foregroundColor:
                                  Colors.white, // keep icon/text white
                              disabledForegroundColor: Colors.white.withOpacity(
                                0.6,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.taskToEdit == null) ...[
                                  const Icon(Icons.check),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  widget.taskToEdit != null ? "Update" : "Add",
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//small widget for ADD Task header
class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _PinnedHeaderDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white, //  avoid transparency when scrolling
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  double get maxExtent => 60;
  @override
  double get minExtent => 60;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
