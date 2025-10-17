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

  const TaskItem({
    super.key,
    required this.task,
    required this.controller,
    this.onEdit,
  });

  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: widget.task.isChecked
                        ? BColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: widget.task.isChecked
                          ? BColors.primary
                          : BColors.grey,
                      width: 2,
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: widget.task.isChecked
                        ? const Icon(
                            Icons.check,
                            size: 16,
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
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
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
                  child: Text(
                    widget.task.tasksTitle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ),

              SizedBox(width: BSizes.sm),

              // Priority chip
              PriorityChip(label: label, color: chipColor),
            ],
          ),
        ),
      ),
    );
  }
}
