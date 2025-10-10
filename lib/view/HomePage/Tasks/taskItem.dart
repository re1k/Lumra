// lib/view/HomePage/Tasks/task_item.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumra_project/model/task/task.dart';
import 'package:lumra_project/controller/task/taskController.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'priorityChip.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final TaskController controller;
  final VoidCallback? onEdit;

  const TaskItem({
    super.key,
    required this.task,
    required this.controller,
    this.onEdit,
  });

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high':
        return BColors.error;
      case 'medium':
        return BColors.warning;
      case 'done':
        return BColors.success;
      default:
        return BColors.info; // low
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    final label = task.priority[0].toUpperCase() + task.priority.substring(1);

    ///To start with capital letter
    final chipColor = _priorityColor(task.priority);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: BSizes.sm),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 253, 254, 253),
        borderRadius: BorderRadius.circular(BSizes.inputFieldRadius),
        border: Border.all(color: BColors.grey),
      ),
      child: Row(
        children: [
          // Checkbox
          Transform.translate(
            offset: const Offset(-8, 0),
            child: Checkbox(
              value: task.isChecked,
              onChanged: (val) async {
                if (val == null) return;
                try {
                  await controller.updateTaskStatus(task.id, val);
                } on FirebaseException catch (_) {}
              },
            ),
          ),

          // Title
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: BSizes.sm,
                right: BSizes.sm,
                top: BSizes.sm,
                bottom: BSizes.sm,
              ),
              child: Transform.translate(
                offset: const Offset(-12, 0),
                child: Text(
                  task.tasksTitle,
                  style: tt.bodyMedium?.copyWith(
                    decoration: task.isChecked
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.isChecked ? Colors.grey : BColors.black,
                  ),
                ),
              ),
            ),
          ),

          // Priority chip
          Transform.translate(
            offset: const Offset(-2, 0),
            child: PriorityChip(label: label, color: chipColor),
          ),
        ],
      ),
    );
  }
}
