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
        Row(
          children: [
            const SizedBox(width: 8),
            const Icon(Icons.access_time, color: BColors.black),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.translate(
                    offset: const Offset(0, 2),
                    child: _SectionLabel(text: 'Reminders'),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -2),
                    child: Padding(
                      padding: const EdgeInsets.only(left: BSizes.sm),
                      child: Text(
                        'Upcoming events in the next 24 hours',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: BColors.darkGrey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    try {
      if (Get.isRegistered<ReminderController>()) {
        _reminderStream =
            Get.find<ReminderController>().upcomingRemindersStream;
      } else {
        _reminderStream = Stream.value(<ReminderModel>[]);
      }
    } catch (e) {
      _reminderStream = Stream.value(<ReminderModel>[]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_reminderStream == null) {
      return _LoadingState();
    }

    return StreamBuilder<List<ReminderModel>>(
      stream: _reminderStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _LoadingState();
        }

        if (snapshot.hasError) {
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
            child: Text(
              'Failed to load reminders',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: BColors.error),
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
    return Container(
      padding: const EdgeInsets.all(BSizes.md),
      child: Center(
        child: Text(
          'Nothing for now, breathe and relax',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: BColors.darkGrey,
            fontStyle: FontStyle.italic,
          ),
        ),
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
  final ScrollController _scrollController = ScrollController();
  bool _showScrollIndicator = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollIndicator();
    });
  }

  @override
  void didUpdateWidget(_RemindersList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reminders != oldWidget.reminders) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateScrollIndicator();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    _updateScrollIndicator();
  }

  void _updateScrollIndicator() {
    if (_scrollController.hasClients) {
      final maxExtent = _scrollController.position.maxScrollExtent;
      final offset = _scrollController.offset;
      final shouldShow = maxExtent > 0 && offset < maxExtent - 5;

      if (shouldShow != _showScrollIndicator) {
        setState(() {
          _showScrollIndicator = shouldShow;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Inside _RemindersListState.build()
    final itemHeight = 80.0;
    final totalHeight = widget.reminders.length * itemHeight;
    final constrainedHeight = totalHeight.clamp(0.0, 230.0);

    return Stack(
      children: [
        Container(
          height: constrainedHeight,
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: BSizes.sm,
              vertical: BSizes.sm,
            ),
            itemCount: widget.reminders.length,
            separatorBuilder: (_, __) => const SizedBox(height: BSizes.sm),
            itemBuilder: (context, index) =>
                _ReminderCard(reminder: widget.reminders[index]),
          ),
        ),
        if (_showScrollIndicator)
          Positioned(
            right: BSizes.sm,
            bottom: BSizes.sm,
            child: _ScrollIndicator(),
          ),
      ],
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
      padding: EdgeInsets.symmetric(horizontal: BSizes.sm),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 253, 254, 253),
        borderRadius: BorderRadius.circular(BSizes.inputFieldRadius),
        border: Border.all(color: BColors.grey),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: BSizes.sm,
                right: BSizes.sm,
                top: BSizes.sm,
                bottom: BSizes.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: BColors.black,
                    ),
                  ),

                  const SizedBox(height: BSizes.xs),

                  Text(
                    reminder.dateTimeRange,
                    style: tt.bodySmall?.copyWith(
                      color: BColors.darkGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScrollIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 0.8,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BSizes.sm,
          vertical: BSizes.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
          border: Border.all(
            color: BColors.primary.withOpacity(0.2),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: BColors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.keyboard_arrow_down,
          size: 18,
          color: BColors.primary,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BSizes.sm,
        vertical: BSizes.xs,
      ),
      decoration: BoxDecoration(
        color: BColors.white,
        borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
        border: Border.all(color: Colors.transparent),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: BColors.texBlack,
        ),
      ),
    );
  }
}
