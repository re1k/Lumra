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
    _userSub = db.collection('users').doc(currentUid).snapshots().listen((
      doc,
    ) async {
      final data = doc.data();
      if (data == null) return;

      final role = (data['role'] as String?)
          ?.trim(); // check role from user doc
      final newLinked = (data['linkedUserId'] as String?)?.trim();

      if (newLinked == null || newLinked.isEmpty) {
        //  has no link yet (only happens in ADHD side)
        //  NOTE: there is no caregiver without adhd, but there is adhd without caregiver
        linkedUid.value = null;
        await _watchMonth(
          visibleMonth.value,
        ); // still watch the ADHDs own events
        return;
      }

      if (linkedUid.value != newLinked) {
        linkedUid.value = newLinked;

        // CAREGIVER-SIDE ASSUMPTION: (the participant must contain the ADHD not the opposite)
        // NOTE: there is no caregiver without adhd → if role == caregiver, a link must exist
        if (role == 'caregiver') {
          await _backfillAdhdUpcomingFromController(
            adhdUid: newLinked,
            caregiverUid: currentUid,
          );
        }

        // re-attach to events whenever linkage changes
        await _watchMonth(visibleMonth.value);
      } else {
        // linked id unchanged; still make sure we’re listening to the right month
        await _watchMonth(visibleMonth.value);
      }
    });
  }

  // One-time helper from controller:
  // Ensure ADHD's UPCOMING events include the caregiver in `participants`.
  // If participants is exactly [adhdUid], replace with [adhdUid, caregiverUid].
  // Else, if caregiver missing, add via arrayUnion (idempotent).
  Future<void> _backfillAdhdUpcomingFromController({
    required String adhdUid,
    required String caregiverUid,
  }) async {
    if (adhdUid.isEmpty || caregiverUid.isEmpty || adhdUid == caregiverUid) {
      return;
    }

    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);

    final snap = await db
        .collection('events')
        .where('participants', arrayContains: adhdUid)
        .get();

    for (final doc in snap.docs) {
      final data = doc.data();

      final ts = data['start'];
      if (ts is! Timestamp) continue;
      final start = ts.toDate();

      if (start.isBefore(todayMidnight)) continue; // only upcoming

      final raw = (data['participants'] ?? const []) as List<dynamic>;
      final list = raw
          .map((e) => e?.toString() ?? '')
          .where((s) => s.trim().isNotEmpty)
          .toList();

      if (list.contains(caregiverUid)) continue;

      if (list.length == 1 && list.first == adhdUid) {
        await doc.reference.update({
          'participants': <String>[adhdUid, caregiverUid],
        });
      } else {
        await doc.reference.update({
          'participants': FieldValue.arrayUnion([caregiverUid]),
        });
      }
    }
  }

  //this method is used to set up or reset the firestor listener for the month containing m
  //which is why we call it in the int and in goToMonth when we move to another month
  // 2)
  Future<void> _watchMonth(DateTime m) async {
    await _eventsSub?.cancel();
    monthEvents.clear(); // avoid showing stale docs while re-subscribing

    final start = monthStart(m);
    final endExcl = monthEndExclusive(m);
    final lu = linkedUid.value?.trim();

    // Build month window
    Query<Map<String, dynamic>> q = db
        .collection('events')
        .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('start', isLessThan: Timestamp.fromDate(endExcl))
        .orderBy('start');

    //Key rule to prevent ADHD-only past events from appearing to caregiver:
    //Whether linked or not, fetch ONLY docs that include the logged-in user (currentUid).
    //Backfill ensures upcoming ADHD events include the caregiver, so they appear naturally.
    q = q.where('participants', arrayContains: currentUid);

    //real tim subscription where firestore pushes a new snap if the matching docs are modified
    _eventsSub = q.snapshots().listen((snap) {
      final map = <DateTime, List<CalendarEvent>>{};

      //iterate over every document in the snapshot
      for (final doc in snap.docs) {
        final ev = CalendarEvent.fromDoc(doc);

        // (Optional sanity) enforce again at client level:
        // if (!ev.participants.contains(currentUid)) continue;

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
