import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/Homepage/Reminders/reminderController.dart';
import 'package:lumra_project/model/Homepage/Reminders/reminderModel.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';

class UpcomingReminders extends StatelessWidget {
  const UpcomingReminders({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: EdgeInsets.only(bottom: BSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upcoming Events',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: BColors.black,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),

        // Reminders content
        _RemindersContent(),
      ],
    );
  }
}

class _RemindersContent extends StatefulWidget {
  @override
  State<_RemindersContent> createState() => _RemindersContentState();
}

class _RemindersContentState extends State<_RemindersContent> {
  Stream<List<ReminderModel>>? _reminderStream;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  void _initializeStream() {
    if (Get.isRegistered<ReminderController>()) {
      final reminderController = Get.find<ReminderController>();
      _reminderStream = reminderController.upcomingRemindersStream;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_reminderStream == null) {
      return _ErrorState(error: 'ReminderController not found');
    }

    return StreamBuilder<List<ReminderModel>>(
      stream: _reminderStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _LoadingState();
        }

        if (snapshot.hasError) {
          // Log the underlying error for debugging
          // ignore: avoid_print
          print('Reminders stream error: ${snapshot.error}');
          return _ErrorState(error: snapshot.error.toString());
        }

        final reminders = snapshot.data ?? [];

        if (reminders.isEmpty) {
          return _EmptyState();
        }

        return _RemindersList(reminders: reminders);
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      child: const Center(
        child: CircularProgressIndicator(color: BColors.primary),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BSizes.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
        border: Border.all(color: BColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: BColors.error, size: 20),
          const SizedBox(width: BSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Failed to load reminders',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: BColors.error),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: BColors.darkGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
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
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.task_alt, color: BColors.primary, size: 20),
          ),
          SizedBox(width: BSizes.md),
          Expanded(
            child: Text(
              'Enjoy the calm! We\'ll remind you when something\'s coming up.',
              style: tt.bodyMedium?.copyWith(
                color: BColors.black,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _RemindersList extends StatefulWidget {
  final List<ReminderModel> reminders;

  const _RemindersList({required this.reminders});

  @override
  State<_RemindersList> createState() => _RemindersListState();
}

class _RemindersListState extends State<_RemindersList> {
  @override
  Widget build(BuildContext context) {
    // Show all reminders without height constraints
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: BSizes.xs),
      itemCount: widget.reminders.length,
      separatorBuilder: (_, __) => const SizedBox(height: BSizes.sm),
      itemBuilder: (context, index) =>
          _ReminderCard(reminder: widget.reminders[index]),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderModel reminder;

  const _ReminderCard({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

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
          SizedBox(width: BSizes.sm),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: BColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: BSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: BColors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                SizedBox(height: BSizes.xs),
                Text(
                  reminder.dateTimeRange,
                  style: tt.bodySmall?.copyWith(
                    color: BColors.darkGrey,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
