import 'package:flutter/material.dart';
import 'package:lumra_project/model/Homepage/Calendar/calendarModel.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/view/Homepage/Calendar/calendarWidgets/format.dart';

class EventTile extends StatelessWidget {
  final CalendarEvent event;

  //constructor with the required events
  const EventTile({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final time = //twoDigit is helper for zero-padding hours/minutes (HH:MM - HH:MM)
        '${twoDigit(event.start.hour)}:${twoDigit(event.start.minute)} - ${twoDigit(event.end.hour)}:${twoDigit(event.end.minute)}';

    return Container(
      //container that contains the event
      decoration: BoxDecoration(
        color: BColors.primary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BColors.primary),
      ),

      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ), //horizontal and vertical padding
        //add the dot
        leading: Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: BColors.primary,
            shape: BoxShape.circle,
          ),
        ),

        //add the text
        title: Text(
          event.title,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(time, style: textTheme.bodySmall),

        //add the edit icon
        trailing: IconButton(
          tooltip: 'Edit event',
          icon: const Icon(Icons.edit, color: Colors.grey),
          onPressed: null, // placeholder for now
        ),
      ),
    );
  }
}
