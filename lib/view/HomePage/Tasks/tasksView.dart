// lib/view/HomePage/Tasks/tasks_list.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumra_project/controller/task/taskController.dart';
import 'package:lumra_project/model/task/task.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'taskItem.dart';
import 'addTaskSheet.dart';

class TasksList extends StatelessWidget {
  final TaskController controller;
  const TasksList({super.key, required this.controller});

  Future<void> openAddTaskSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BSizes.borderRadiusLg),
        ),
      ),
       builder: (context) => FractionallySizedBox(
          heightFactor: 0.45, // to make it Covers 85% of screen height
          child:  AddTaskSheet(controller: controller), //in here i added my view
        ),
     // builder: (_) => AddTaskSheet(controller: controller),
    );
  }

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

        return ListView.separated(
          itemCount: tasks.length,
          separatorBuilder: (_, __) => SizedBox(height: BSizes.xs),
          itemBuilder: (_, i) =>
              TaskItem(task: tasks[i], controller: controller),
        );
      },
    );
  }
}
