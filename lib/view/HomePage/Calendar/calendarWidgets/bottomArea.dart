import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/Homepage/Calendar/addEventController.dart';
import 'package:lumra_project/model/Homepage/Calendar/calendarModel.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
//import 'package:lumra_project/view/HomePage/Calendar/eventWidgets/addEventView.dart';
import 'package:lumra_project/view/Homepage/Calendar/calendarWidgets/eventTitle.dart';
import 'package:lumra_project/view/Homepage/Calendar/calendarWidgets/format.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lumra_project/view/Homepage/Calendar/eventWidgets/addEventView.dart';

class BottomArea extends StatelessWidget {
  final DateTime selected;
  final List<CalendarEvent> events;
  // final onAddTap; REEM

  const BottomArea({super.key, required this.selected, required this.events});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final dateLabel =
        '${weekdayName(selected.weekday)}, ${monthName(selected.month)} ${selected.day}';

    final today = DateTime.now();
    final isPastDay = DateTime(
      selected.year,
      selected.month,
      selected.day,
    ).isBefore(DateTime(today.year, today.month, today.day));
    final canAdd = !isPastDay;

    void _openAddSheet() {
      //made it looks like popping up from the bottom
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: BColors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        builder: (context) => FractionallySizedBox(
          heightFactor: 0.75, // to make it Covers 85% of screen height
          child: AddEventView(),
        ),
      );
      // when the sheet closes, dispose controller → triggers onClose
      Get.delete<AddEventController>();
    }

    //if there is no events it is going to contain "Tue, September 30" + the add button
    if (events.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 19, vertical: 12),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
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
        child: Column(
          children: [
            SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      dateLabel,
                      style: (textTheme.titleMedium ?? const TextStyle())
                          .copyWith(
                            fontWeight: FontWeight.w600,
                            color: BColors.black,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: canAdd
                        ? BColors.primary
                        : BColors.darkGrey.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    Icons.add,
                    size: 14,
                    color: canAdd
                        ? BColors.white
                        : BColors.darkGrey.withOpacity(0.5),
                  ),
                  label: Text(
                    'Add Event',
                    style: textTheme.labelMedium?.copyWith(
                      color: canAdd
                          ? BColors.white
                          : BColors.darkGrey.withOpacity(0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: canAdd ? _openAddSheet : null, // disabled if past
                ),
              ],
            ),
          ],
        ),
      );
    }

    //if there is event then it will contain the events (ordered) with a '+' icon to add more
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 19, vertical: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 35),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Text(
                    dateLabel,
                    style: (textTheme.titleMedium ?? const TextStyle())
                        .copyWith(
                          fontWeight: FontWeight.w700,
                          color: BColors.black,
                        ),
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: canAdd
                      ? BColors.primary.withOpacity(0.1)
                      : BColors.darkGrey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  tooltip: canAdd
                      ? 'Add event'
                      : 'Cannot add events to past dates',
                  icon: Icon(
                    Icons.add,
                    color: canAdd
                        ? BColors.primary
                        : BColors.darkGrey.withOpacity(0.5),
                    size: 16,
                  ),
                  onPressed: canAdd ? _openAddSheet : null, // disabled if past
                ),
              ),
              SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ClipRect(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => SizedBox(height: BSizes.sm),
                  //to add the event + make it slidable for deleting
                  itemBuilder: (context, i) => Slidable(
                    key: ValueKey(events[i].id),
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      extentRatio: 0.26,
                      children: [
                        SlidableAction(
                          onPressed: null, //only UI for now
                          backgroundColor: BColors.error,
                          foregroundColor: BColors.white,
                          icon: Icons.delete,
                          label: 'Delete',
                          borderRadius: BorderRadius.circular(12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ],
                    ),
                    child: EventTile(event: events[i]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
