import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../model/Homepage/Calendar/calendarModel.dart';

//Helper function that takes the DateTime and returns another date
//because when displaying the calander we want to display the days from the first day to the last day (not including the first day of the next month)
DateTime monthStart(DateTime d) => DateTime(d.year, d.month, 1);
DateTime monthEndExclusive(DateTime d) => DateTime(d.year, d.month + 1, 1);

//This class is needed to maintain a shared calander
class UserScope {
  final String userId;
  final String? linkedUserId; // null if not linked

  const UserScope({required this.userId, this.linkedUserId});

  //returns the linkedUserID and userID (if it is a caregiver their will always be a linked ADHD but the opposite is not true)
  List<String> get queryIds =>
      linkedUserId?.isNotEmpty == true ? [userId, linkedUserId!] : [userId];
}

////////////////////////////////////////////////////////////////////

class CalendarController extends GetxController {
  final FirebaseFirestore db;
  final UserScope scope;
  CalendarController(this.db, this.scope);

  final visibleMonth = monthStart(
    DateTime.now(),
  ).obs; //the current month is the month that is going to appear
  final selectedDay = Rxn<DateTime>();
  final monthEvents = <DateTime, List<CalendarEvent>>{}
      .obs; //contains each day with the list of events assigned to that day

  StreamSubscription? _sub;

  //runs once when the controller is created and calls the method _watchMonth
  @override
  void onInit() {
    super.onInit();
    _watchMonth(visibleMonth.value);
  }

  //it is used when moving between the months, and sets the previously selected day to null
  //resubscribes to the firestore by calling the method _watchMonth
  Future<void> goToMonth(DateTime m) async {
    visibleMonth.value = monthStart(m);
    selectedDay.value = null;
    await _watchMonth(visibleMonth.value);
  }

  //stores the selected day to present the available events
  void onDayTapped(DateTime day) {
    if (day.month != visibleMonth.value.month) return; // ignore padding cells
    selectedDay.value = day;
  }

  //checks if the day has at least one event
  bool hasEvent(DateTime day) =>
      monthEvents.containsKey(DateTime(day.year, day.month, day.day));

  //returns the list of events in one day or an empty list
  List<CalendarEvent> eventsFor(DateTime day) =>
      monthEvents[DateTime(day.year, day.month, day.day)] ?? const [];

  //this method is used to set up or reset the firestor listener for the month containing m
  //which is why we call it in the int and in goToMonth when we move to another month
  Future<void> _watchMonth(DateTime m) async {
    //if there is stream from the previous month it will cancel it
    await _sub?.cancel();

    //to find the first day of the month and the first day of the previous month (exclusive so not included)
    final start = monthStart(m);
    final endExcl = monthEndExclusive(m);

    //reads from the events collection those who contain current user or their linked user in participants
    final q = db
        .collection('events')
        .where('participants', arrayContainsAny: scope.queryIds)
        .where(
          'start',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        ) //to ensure they are events of the selected month
        .where('start', isLessThan: Timestamp.fromDate(endExcl))
        .orderBy('start');

    //real tim subscription where firestore pushes a new snap if the matching docs are modified
    _sub = q.snapshots().listen((snap) {
      final map = <DateTime, List<CalendarEvent>>{};

      //iterate over every document in the snapshot
      for (final doc in snap.docs) {
        final ev = CalendarEvent.fromDoc(doc);
        final key = DateTime(ev.start.year, ev.start.month, ev.start.day);
        (map[key] ??= <CalendarEvent>[]).add(ev);
      }

      //Inside each day, sort events by their start time so the UI shows them in order
      for (final list in map.values) {
        list.sort((a, b) => a.start.compareTo(b.start));
      }

      monthEvents.assignAll(map); //notify observers (Obx) reactively
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
