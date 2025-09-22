import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/Homepage/Calendar/calendarController.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/view/HomePage/Calendar/eventWidgets/addEventView.dart';
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
    _pager = PageController(initialPage: _center);
    final now = DateTime.now();
    _anchorMonth = DateTime(now.year, now.month, 1);
    c = Get.find<CalendarController>(); // by class name
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
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
    final appBarTitleStyle =
        Theme.of(context).appBarTheme.titleTextStyle ?? textTheme.titleLarge;

    return Scaffold(
      //provide page structure
      appBar: AppBar(
        //what appears at the top of the page
        iconTheme: const IconThemeData(
          color: BColors.white,
        ), // back arrow color goes back to the caller
        title: Obx(() {
          final m = c.visibleMonth.value;
          return Text(
            '${monthName(m.month)} ${m.year}', //the text displayed like: "September 2025"
            style: appBarTitleStyle?.copyWith(color: BColors.white),
          );
        }),

        //icons to navigate between the months
        actions: [
          IconButton(
            tooltip: 'Previous month',
            icon: const Icon(Icons.chevron_left, color: BColors.white),
            onPressed: () => _pager.previousPage(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            ),
          ),
          IconButton(
            tooltip: 'Next month',
            icon: const Icon(Icons.chevron_right, color: BColors.white),
            onPressed: () => _pager.nextPage(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const WeekdayHeader(), // Sun..Sat (fixed)
          Expanded(
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

          //if no day selected render nothing, otherwise, render "BottomArea"
          Obx(() {
            final d = c.selectedDay.value;
            if (d == null) return const SizedBox.shrink();
            return BottomArea(
              selected: d,
              events: c.eventsFor(d),
              // onAddTap: () { REEM },
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: BColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        onPressed: () {
          //made it looks like popping up from the bottom
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: BColors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            builder: (context) => FractionallySizedBox(
              heightFactor: 0.85, // to make it Covers 85% of screen height
              child: AddEventView(), //in here i added my view
            ),
          );
        },
        //the add icon
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
    );
  }
}
