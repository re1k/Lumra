import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumra_project/model/Homepage/Calendar/calendarModel.dart';

//Helper function that takes the DateTime and returns another date
//because when displaying the calander we want to display the days from the first day to the last day (not including the first day of the next month)
DateTime monthStart(DateTime d) => DateTime(d.year, d.month, 1);
DateTime monthEndExclusive(DateTime d) => DateTime(d.year, d.month + 1, 1);
DateTime justDate(DateTime d) => DateTime(d.year, d.month, d.day);

class CalendarController extends GetxController {
  final FirebaseFirestore db;
  final String currentUid;
  CalendarController(this.db, this.currentUid);

  //the current month is the month that is going to appear
  final visibleMonth = monthStart(DateTime.now()).obs;
  final selectedDay = Rxn<DateTime>();
  //contains each day with the list of events assigned to that day
  final monthEvents = <DateTime, List<CalendarEvent>>{}.obs;

  final RxnString linkedUid = RxnString(); // discovered from users/{uid}
  StreamSubscription? _userSub;
  StreamSubscription? _eventsSub;

  //runs once when the controller is created and calls the method _watchMonth
  @override
  void onInit() {
    super.onInit();

    // auto-select today
    final today = justDate(DateTime.now());
    if (monthStart(today) == visibleMonth.value) {
      selectedDay.value = today;
    }

    _watchLinkedUser(); // keep linkedUid up to date
    _watchMonth(visibleMonth.value);
  }

  //it is used when moving between the months, and sets the previously selected day to null
  //resubscribes to the firestore by calling the method _watchMonth
  Future<void> goToMonth(DateTime m) async {
    visibleMonth.value = monthStart(m);

    // auto-select today when navigating to the current month, otherwise null
    final today = justDate(DateTime.now());
    selectedDay.value = (monthStart(today) == visibleMonth.value)
        ? today
        : null;

    await _watchMonth(visibleMonth.value);
  }

  //stores the selected day to present the available events
  void onDayTapped(DateTime day) {
    if (day.month != visibleMonth.value.month)
      return; // ignore padding cells that are added for the overall style
    selectedDay.value = justDate(day);
  }

  //checks if the day has at least one event
  bool hasEvent(DateTime day) =>
      monthEvents.containsKey(DateTime(day.year, day.month, day.day));

  //returns the list of events in one day or an empty list
  List<CalendarEvent> eventsFor(DateTime day) =>
      monthEvents[DateTime(day.year, day.month, day.day)] ?? const [];

  // 1) Listen to users/{currentUid} to get the partner (caregiver or ADHD)
  void _watchLinkedUser() {
    _userSub = db.collection('users').doc(currentUid).snapshots().listen((doc) {
      final newLinked = (doc.data()?['linkedUserId'] as String?)?.trim();
      if (linkedUid.value != newLinked) {
        linkedUid.value = newLinked;
        // re-attach to events whenever linkage changes
        _watchMonth(visibleMonth.value);
      }
    });
  } //ASK THE GIRLS, DO WE ALLOW THE CAREGIVER TO CHANGE?

  //this method is used to set up or reset the firestor listener for the month containing m
  //which is why we call it in the int and in goToMonth when we move to another month
  // 2) Always query for BOTH currentUid and linkedUid (when present)
  Future<void> _watchMonth(DateTime m) async {
    //if there is stream from the previous month it will cancel it
    await _eventsSub?.cancel();

    //to find the first day of the month and the first day of the previous month (exclusive so not included)
    final start = monthStart(m);
    final endExcl = monthEndExclusive(m);

    // Build the participants filter WITHOUT null/empty
    final ids = <String>{currentUid};
    final lu = linkedUid.value;
    if (lu != null && lu.isNotEmpty) ids.add(lu);
    final idList = ids.toList();

    Query<Map<String, dynamic>> q = db.collection('events');
    // When only one id, arrayContains is simpler
    if (idList.length == 1) {
      q = q.where('participants', arrayContains: idList.first);
    } else {
      q = q.where('participants', arrayContainsAny: idList);
    }

    //ensure the event is in the current month
    q = q
        .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('start', isLessThan: Timestamp.fromDate(endExcl))
        .orderBy('start');

    //real tim subscription where firestore pushes a new snap if the matching docs are modified
    _eventsSub = q.snapshots().listen((snap) {
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
    _userSub?.cancel();
    _eventsSub?.cancel();
    super.onClose();
  }
}
