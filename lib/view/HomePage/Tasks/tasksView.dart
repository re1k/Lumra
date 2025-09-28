// lib/view/HomePage/Tasks/tasks_list.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumra_project/controller/task/taskController.dart';
import 'package:lumra_project/model/task/task.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'taskItem.dart';
import 'addTaskSheet.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';

class TasksList extends StatelessWidget {
  final TaskController controller;
  const TasksList({super.key, required this.controller});

  Future<void> openAddTaskSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6, // 80% tall when first shown
        minChildSize: 0.5, // can shrink down to 50%
        maxChildSize: 0.6, // can grow up to 60% max (no white sheet appears)
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: AddTaskSheet(controller: controller),
          );
        },
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Task>>(
      stream: controller.getTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Stream error: ${snapshot.error}'));
        }
        final tasks = snapshot.data ?? const <Task>[];
        if (tasks.isEmpty) {
          return const Center(child: Text('No tasks yet, press ➕ to add'));
        }

        return ReorderableListView.builder(
          padding: EdgeInsets.only(bottom: BSizes.md),
          itemCount: tasks.length,
          onReorder: (oldIndex, newIndex) => controller.reorderTasks(
            List<Task>.from(tasks),
            oldIndex,
            newIndex,
          ),
          itemBuilder: (context, i) {
            final t = tasks[i];
            return Dismissible(
              key: ValueKey(t.id),
              direction: DismissDirection.endToStart, // only allow left swipe
              background: const _SwipeDeleteBg(),
              confirmDismiss: (dir) async {
                if (dir == DismissDirection.endToStart) {
                  await controller.deleteTask(t.id);
                  return true; // remove from list
                }
                return false;
              },
              child: Padding(
                padding: EdgeInsets.only(bottom: BSizes.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Drag handle
                    ReorderableDragStartListener(
                      index: i,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(Icons.drag_handle, color: Colors.grey),
                      ),
                    ),

                    // Task item takes the rest of the space
                    Expanded(
                      child: TaskItem(task: t, controller: controller),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SwipeDeleteBg extends StatelessWidget {
  const _SwipeDeleteBg();
  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    color: BColors.error.withOpacity(.2),
    child: const Icon(Icons.delete_outline, size: 28),
  );
}
