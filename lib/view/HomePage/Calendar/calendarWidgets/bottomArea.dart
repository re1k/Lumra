import 'package:flutter/material.dart';
import 'package:lumra_project/model/Homepage/Calendar/calendarModel.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
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
        backgroundColor: BColors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        builder: (context) => FractionallySizedBox(
          heightFactor: 0.70, // to make it Covers 85% of screen height
          child: AddEventView(), //in here i added my view
        ),
      );
    }

    //if there is no events it is going to contain "Tue, September 30" + the add button
    if (events.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: BColors.primary.withOpacity(0.3),
          border: Border(top: BorderSide(color: BColors.black)),
        ),
        child: Row(
          children: [
            Text(
              dateLabel,
              style: (textTheme.titleMedium ?? const TextStyle()).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor:
                    BColors.buttonPrimary, // set background color here
              ),
              icon: const Icon(Icons.add),
              label: Text(
                'Add',
                style: textTheme.labelLarge?.copyWith(color: BColors.white),
              ),
              onPressed: canAdd ? _openAddSheet : null, // disabled if past
            ),
          ],
        ),
      );
    }

    //if there is event then it will contain the events (ordered) with a '+' icon to add more
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: BColors.lightContainer,
        border: Border(top: BorderSide(color: BColors.darkerGrey)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  dateLabel,
                  style: (textTheme.titleMedium ?? const TextStyle()).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Add event',
                  icon: const Icon(Icons.add),
                  onPressed: canAdd ? _openAddSheet : null, // disabled if past
                ),
              ],
            ),
            const SizedBox(height: 6),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  //to add the event + make it slidable for deleting
                  itemBuilder: (context, i) => Slidable(
                    key: ValueKey(events[i].id),
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      extentRatio: 0.24,
                      children: [
                        SlidableAction(
                          onPressed: null, //only UI for now
                          backgroundColor: BColors.error,
                          foregroundColor: BColors.white,
                          icon: Icons.delete,
                          label: 'Delete',
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ],
                    ),
                    child: EventTile(event: events[i]),
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
