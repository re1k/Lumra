import 'package:flutter/material.dart';
import 'package:lumra_project/model/Homepage/Calendar/calendarModel.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
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
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: EdgeInsets.symmetric(horizontal: BSizes.md, vertical: BSizes.sm),
      decoration: BoxDecoration(
        color: BColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
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
                  event.title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: BColors.black,
                  ),
                  overflow: TextOverflow.visible,
                  maxLines: null,
                ),
                SizedBox(height: BSizes.xs),
                Text(
                  time,
                  style: textTheme.bodySmall?.copyWith(
                    color: BColors.darkGrey,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          SizedBox(width: BSizes.sm),
          IconButton(
            tooltip: 'Edit event',
            icon: const Icon(Icons.edit, color: BColors.darkGrey, size: 18),
            onPressed: null, // placeholder for now
          ),
        ],
      ),
    );
  }
}
