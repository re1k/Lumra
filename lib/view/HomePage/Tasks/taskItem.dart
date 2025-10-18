// lib/view/HomePage/Tasks/task_item.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumra_project/model/task/task.dart';
import 'package:lumra_project/controller/task/taskController.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'priorityChip.dart';

class TaskItem extends StatefulWidget {
  final Task task;
  final TaskController controller;
  final VoidCallback? onEdit;
  final int? index;

  const TaskItem({
    super.key,
    required this.task,
    required this.controller,
    this.onEdit,
    this.index,
  });

  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> {
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

    final label =
        widget.task.priority[0].toUpperCase() +
        widget.task.priority.substring(1);

    ///To start with capital letter
    final chipColor = _priorityColor(widget.task.priority);

    return Container(
      padding: EdgeInsets.all(BSizes.md),
      decoration: BoxDecoration(
        color: BColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Reorder handle
          SizedBox(
            width: 24,
            height: 24,
            child: widget.index != null
                ? ReorderableDragStartListener(
                    index: widget.index!,
                    child: Icon(
                      Icons.drag_handle,
                      size: 20,
                      color: BColors.grey,
                    ),
                  )
                : Icon(Icons.drag_handle, size: 20, color: BColors.grey),
          ),

          SizedBox(width: BSizes.sm),

          // Checkbox
          GestureDetector(
            onTap: () async {
              try {
                await widget.controller.updateTaskStatus(
                  widget.task.id,
                  !widget.task.isChecked,
                );
              } on FirebaseException catch (_) {}
            },
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: widget.task.isChecked
                    ? BColors.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: widget.task.isChecked ? BColors.primary : BColors.grey,
                  width: 2,
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.elasticOut,
                      ),
                    ),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: widget.task.isChecked
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: BColors.white,
                        key: ValueKey('check'),
                      )
                    : const SizedBox(key: ValueKey('empty')),
              ),
            ),
          ),

          SizedBox(width: BSizes.md),

          // Title
          Expanded(
            child: Text(
              widget.task.tasksTitle,
              style:
                  tt.bodyMedium?.copyWith(
                    decoration: widget.task.isChecked
                        ? TextDecoration.lineThrough
                        : null,
                    color: widget.task.isChecked
                        ? BColors.darkGrey
                        : BColors.black,
                    fontWeight: FontWeight.w500,
                  ) ??
                  const TextStyle(),
            ),
          ),

          SizedBox(width: BSizes.sm),

          // Priority chip
          PriorityChip(label: label, color: chipColor),
        ],
      ),
    );
  }
}
