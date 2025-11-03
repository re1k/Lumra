// lib/view/HomePage/Tasks/tasksView.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lumra_project/controller/task/taskController.dart';
import 'package:lumra_project/model/task/task.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'taskItem.dart';
import 'addTaskSheet.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/utils/customWidgets/toastservice.dart';

class TasksList extends StatefulWidget {
  final TaskController controller;
  const TasksList({super.key, required this.controller});

  @override
  State<TasksList> createState() => _TasksListState();

  // Static method to open add task sheet
  static Future<void> openAddTaskSheet(
    BuildContext context,
    TaskController controller,
  ) async {
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
        initialChildSize: 0.7, // 80% tall when first shown
        minChildSize: 0.5, // can shrink down to 50%
        maxChildSize: 0.7, // can grow up to 60% max (no white sheet appears)
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: AddTaskSheet(controller: controller),
          );
        },
      ),
    );
  }
}

class _TasksListState extends State<TasksList> {
  // Reorder control and task sources
  bool _isReordering = false;
  List<Task> _liveTasks = <Task>[]; // latest from stream (when not reordering)
  List<Task> _currentTasks = <Task>[]; // driving the UI always
  bool _awaitingStreamSync = false; // wait until Firestore order matches local

  bool _ordersMatch(List<Task> a, List<Task> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  Future<void> _deleteTaskWithConfirmation(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 24,
          ),
          title: const Text(
            "Delete",
            style: TextStyle(fontFamily: 'K2D', fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to delete this task?",
            style: TextStyle(
              fontFamily: 'K2D',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                "Cancel",
                style: TextStyle(fontFamily: 'K2D', color: Colors.black87),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: BColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                minimumSize: const Size(90, 40),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Confirm",
                style: TextStyle(
                  fontFamily: 'K2D',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        await widget.controller.deleteTask(task.id);
      } catch (e) {
        if (mounted) {
          ToastService.error('Failed to delete task');
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _openEditTaskModal(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7, // 70% tall when first shown
        minChildSize: 0.5, // can shrink down to 50%
        maxChildSize: 0.7, // can grow up to 70% max
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: AddTaskSheet(
              controller: widget.controller,
              taskToEdit: task,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Task>>(
      stream: widget.controller.getTasks(),
      builder: (context, snapshot) {
        // Show loader only on first ever load, never after reordering
        if (snapshot.connectionState == ConnectionState.waiting) {
          final isFirstLoad =
              _currentTasks.isEmpty && !_isReordering && !_awaitingStreamSync;
          if (isFirstLoad) {
            return const Center(child: CircularProgressIndicator());
          }
          // Otherwise keep showing current UI without any loading
        }
        if (snapshot.hasError) {
          return Center(child: Text('Stream error: ${snapshot.error}'));
        }

        final incoming = (snapshot.data ?? const <Task>[]).toList();

        // While reordering, freeze the UI order by ignoring incoming updates
        if (_isReordering) {
          // If we've persisted and the stream order now matches local, release the gate
          if (_awaitingStreamSync && _ordersMatch(incoming, _currentTasks)) {
            _liveTasks = List<Task>.from(incoming);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _awaitingStreamSync = false;
                  _isReordering = false;
                  // Keep _currentTasks as-is (already matches), avoiding any visual change
                });
              }
            });
          }
        } else {
          // Accept new live tasks and drive UI from them
          _liveTasks = List<Task>.from(incoming);
          _currentTasks = List<Task>.from(_liveTasks);
        }

        if (_currentTasks.isEmpty) {
          return Container(
            padding: EdgeInsets.all(BSizes.md),
            decoration: BoxDecoration(
              color: BColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: BColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.checklist,
                      color: BColors.primary,
                      size: 24,
                    ),
                  ),
                  SizedBox(height: BSizes.md),
                  Text(
                    'No tasks yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: BColors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: BSizes.xs),
                  Text(
                    'Tap the + icon to add your first task',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BColors.darkGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_currentTasks.isNotEmpty)
              _TasksReorderableList(
                tasks: _currentTasks,
                isReordering: _isReordering,
                controller: widget.controller,
                onDelete: _deleteTaskWithConfirmation,
                onEdit: _openEditTaskModal,
                onReorder: _handleReorder,
              ),
          ],
        );
      },
    );
  }

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    // Normalize indexes like ReorderableListView expects
    int from = oldIndex;
    int to = newIndex;
    if (from < to) to -= 1;

    // Keep a copy for backend write to avoid double-move
    final before = List<Task>.from(_currentTasks);

    setState(() {
      _isReordering = true;
      _awaitingStreamSync = true;
      final item = _currentTasks.removeAt(from);
      _currentTasks.insert(to, item);
    });

    try {
      // Persist only once after drop using the pre-move list and indices
      await widget.controller.reorderTasks(before, oldIndex, newIndex);
    } catch (_) {
      // Avoid UI changes here per spec
    } finally {}
  }
}

class _TasksReorderableList extends StatefulWidget {
  final List<Task> tasks;
  final bool isReordering;
  final TaskController controller;
  final Function(Task) onDelete;
  final Function(Task) onEdit;
  final Future<void> Function(int oldIndex, int newIndex) onReorder;

  const _TasksReorderableList({
    required this.tasks,
    required this.isReordering,
    required this.controller,
    required this.onDelete,
    required this.onEdit,
    required this.onReorder,
  });

  @override
  State<_TasksReorderableList> createState() => _TasksReorderableListState();
}

class _TasksReorderableListState extends State<_TasksReorderableList> {
  // Thin view: parent fully controls ordering/state.

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      key: const ValueKey('tasks_list'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: widget.tasks.length,
      onReorder: widget.onReorder,
      proxyDecorator: (child, index, animation) {
        return ClipRRect(
          borderRadius: BorderRadius.zero, // No corners during drag
          child: Material(
            color: Colors.transparent, // No background
            shadowColor: Colors.transparent, // No shadows
            child: child,
          ),
        );
      },
      itemBuilder: (context, i) {
        final t = widget.tasks[i];
        final tile = Padding(
          key: ValueKey(t.id),
          padding: EdgeInsets.only(bottom: BSizes.md),
          child: _SwipeableTaskItem(
            task: t,
            controller: widget.controller,
            onEdit: () => widget.onEdit(t),
            onDelete: () => widget.onDelete(t),
            index: i,
          ),
        );

        // Smoothly animate when a different task occupies this index
        return AnimatedSwitcher(
          key: ValueKey(t.id),
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) {
            final offsetTween = Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            );
            return FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: offsetTween.animate(anim),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(key: ValueKey('${t.id}_$i'), child: tile),
        );
      },
    );
  }
}

class _SwipeableTaskItem extends StatefulWidget {
  final Task task;
  final TaskController controller;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final int index;

  const _SwipeableTaskItem({
    required this.task,
    required this.controller,
    required this.onEdit,
    required this.onDelete,
    required this.index,
  });

  @override
  State<_SwipeableTaskItem> createState() => _SwipeableTaskItemState();
}

class _SwipeableTaskItemState extends State<_SwipeableTaskItem> {
  double _dragOffset = 0.0;
  static const double _actionWidth = 60.0;
  static const double _maxDragDistance = _actionWidth * 2;

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(
        -_maxDragDistance,
        0.0,
      );
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _dragOffset = _dragOffset < -_maxDragDistance / 2
          ? -_maxDragDistance
          : 0.0;
    });
  }

  void _handleTapDown(TapDownDetails details) {
    if (_dragOffset != 0.0) {
      setState(() => _dragOffset = 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: GestureDetector(
        onHorizontalDragUpdate: _handleDragUpdate,
        onHorizontalDragEnd: _handleDragEnd,
        onTapDown: _handleTapDown,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Background action buttons - only visible when swiped
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit button
                  GestureDetector(
                    onTap: () {
                      setState(() => _dragOffset = 0.0);
                      widget.onEdit();
                    },
                    child: Container(
                      width: _actionWidth,
                      decoration: BoxDecoration(
                        color: BColors.info.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.edit, size: 24, color: BColors.info),
                      ),
                    ),
                  ),
                  // Delete button
                  GestureDetector(
                    onTap: () {
                      setState(() => _dragOffset = 0.0);
                      widget.onDelete();
                    },
                    child: Container(
                      width: _actionWidth,
                      decoration: BoxDecoration(
                        color: BColors.error.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.delete_outline,
                          size: 24,
                          color: BColors.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Foreground task item that slides - covers background when not swiped
            AnimatedContainer(
              duration: const Duration(milliseconds: 10),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(_dragOffset, 0, 0),
              color: BColors.white,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) {
                  final keyVal = (child.key is ValueKey)
                      ? (child.key as ValueKey).value
                      : '';
                  final isUncheckedEntering = keyVal == 'checked-false';
                  final beginOffset = isUncheckedEntering
                      ? const Offset(0, -0.02)
                      : const Offset(0, 0.02);
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: beginOffset,
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey('checked-${widget.task.isChecked}'),
                  child: TaskItem(
                    key: ValueKey(
                      '${widget.task.id}_${widget.task.priority}_${widget.task.isChecked}',
                    ),
                    task: widget.task,
                    controller: widget.controller,
                    index: widget.index,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
