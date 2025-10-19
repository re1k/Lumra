import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/Homepage/Calendar/calendarController.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/view/Homepage/Calendar/calendarWidgets/monthGrid.dart';
import 'package:lumra_project/view/Homepage/Calendar/calendarWidgets/weekdayHeader.dart';
import 'package:lumra_project/view/Homepage/Calendar/calendarWidgets/bottomArea.dart';
import 'package:lumra_project/view/Homepage/Calendar/calendarWidgets/format.dart';

//declaring a stateful CalendarPage screen, and telling the flutter which state class to build for this widget
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final PageController
  _pager; //PageController is from flutte whcih does the following: 1-control which page is visible 2- listen to page changes 3- scroll control
  static const int _center =
      1000; // middle page index -> which allows the user to swipe left and right without running out of pages
  late final DateTime _anchorMonth; // first day of current month
  late final CalendarController
  c; // GetX controller (already registered earlier)
  //the controller was registered when method openCalendar was called -> then it navigated to this page to build the view

  //lifecycle starts here:
  //1- initState
  //2- create the page controller starting at _center(we initialized its value before)
  //3- grab the current time
  //4- _anchorMonth contain the firts day of the current month
  //5- in openCalander we used Get.put to put the CalendarController into GetX’s dependency graph -> here we will search for the same instance registered earlier
  @override
  void initState() {
    super.initState();

    c = Get.find<CalendarController>();

    final now = DateTime.now();
    _anchorMonth = DateTime(now.year, now.month, 1);
    c.visibleMonth.value = _anchorMonth; // force reset to current month
    c.selectedDay.value = DateTime(
      now.year,
      now.month,
      now.day,
    ); // auto-select today

    _pager = PageController(initialPage: _center);
  }

  // Convert a page index to a month DateTime (first day)
  //Each page in the PageView represents one calendar month, we start the PageController at index _center (page 1000). That page corresponds to the current month, so we need a way to turn any arbitrary page index (i) into a month
  DateTime _monthForIndex(int idx) {
    final delta =
        idx -
        _center; //delta=0 -> current month, delta=-1 -> one month before, delta=1 -> one month after
    return DateTime(_anchorMonth.year, _anchorMonth.month + delta, 1);
  }

  //
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: BColors.lightGrey,
      body: SafeArea(
        child: Column(
          children: [
            // header
            Padding(
              padding: EdgeInsets.all(BSizes.lg),
              child: Row(
                children: [
                  // Back arrow icon
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: BColors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: BColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                  SizedBox(width: BSizes.sm),
                  Expanded(
                    child: Obx(() {
                      final m = c.visibleMonth.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${monthName(m.month)} ${m.year}',
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: BColors.black,
                                fontSize: 24,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                  SizedBox(width: BSizes.sm),
                  // Navigation buttons
                  Container(
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Previous month',
                          icon: const Icon(
                            Icons.chevron_left,
                            color: BColors.primary,
                          ),
                          onPressed: () => _pager.previousPage(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Next month',
                          icon: const Icon(
                            Icons.chevron_right,
                            color: BColors.primary,
                          ),
                          onPressed: () => _pager.nextPage(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Calendar content
            Expanded(
              child: Column(
                children: [
                  const WeekdayHeader(), // Sun..Sat (fixed)
                  Expanded(
                    child: Column(
                      children: [
                        // Calendar grid with bottom spacing
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: PageView.builder(
                              controller: _pager,
                              onPageChanged: (i) => c.goToMonth(
                                _monthForIndex(i),
                              ), //notify the contoller when the page changes
                              //each page is a MonthGrid wrapped in Obx so that the selected day and event dots update reactively
                              itemBuilder: (_, i) => Obx(
                                () => MonthGrid(
                                  month: _monthForIndex(i),
                                  hasEvent: c.hasEvent,
                                  selected: c.selectedDay.value,
                                  onTapDay: c.onDayTapped,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Bottom area with proper spacing
                        Obx(() {
                          final d = c.selectedDay.value;
                          if (d == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 40),
                            child: BottomArea(
                              key: ValueKey('${d.year}-${d.month}-${d.day}'),
                              selected: d,
                              events: c.eventsFor(d),
                              // onAddTap: () { REEM },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
