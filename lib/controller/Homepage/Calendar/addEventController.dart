import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/Homepage/Calendar/calendarController.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/utils/customWidgets/toastservice.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEventController extends GetxController {
  
 //for current User
  final FirebaseFirestore db;
  final String currentUid;
  late final CalendarController calendarController;

 //The Inputs
  final titleController = TextEditingController();
  final eventStart = Rxn<Timestamp>();
  final eventEnd = Rxn<Timestamp>();

  AddEventController(this.db, this.currentUid);


  //to get the date from the calander controller
  @override
  void onInit() {
    super.onInit();
    // register CalendarController if needed
    if (!Get.isRegistered<CalendarController>()) {
      calendarController = Get.put(CalendarController(this.db, this.currentUid));
    } else {
      calendarController = Get.find<CalendarController>();
    } }


 // Pick time
  Future<void> pickTime({required bool isStart}) async {
    
    // Get the day chosen from the calendar
    final baseDate = Get.find<CalendarController>().selectedDay.value;

    if (baseDate == null) {
      ToastService.error("Please select a date first");
      return;
    }

    // Open the time picker in input mode
    final TimeOfDay? time = await showTimePicker(
      context: Get.context!,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input, //number input mode
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: BColors.buttonPrimary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            timePickerTheme: TimePickerThemeData(
              dayPeriodColor: BColors.accent,
              dayPeriodTextColor: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      // Merging the chosen date (from calendar) with the chosen time
      final finalDateTime = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        time.hour,
        time.minute,
      );

      // Save into The Rx values
      if (isStart) {
        eventStart.value = Timestamp.fromDate(finalDateTime);
      } else {
        eventEnd.value = Timestamp.fromDate(finalDateTime);
      }
    }
  }

  // Validation
  bool validateEvent() {
    if (titleController.text.trim().isEmpty) {
      ToastService.error("Title is required");
      return false;
    }
    if (eventStart.value == null) {
      ToastService.error("Start time is required");
      return false;
    }
    if (eventEnd.value == null) {
      ToastService.error("End time is required");
      return false;
    }
    if (eventEnd.value!.toDate().isBefore(eventStart.value!.toDate())) {
      ToastService.error("End time cannot be before start time");
      return false;
    }
    return true;
  }

  // Now adding the event
  Future<void> addEventToFirebase() async {
    if (!validateEvent()) return;

    try {
      // Fetch the current user document
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUid)
          .get();

      // Extract caregiverId if any
      final userData = userDoc.data();
      final caregiverId = userData?["linkedUserId"];

      //linking the event with the other user
      final participants = [currentUid];
      if (caregiverId != null && caregiverId.toString().isNotEmpty) {
        participants.add(caregiverId);
      }

      //Add event
      await FirebaseFirestore.instance.collection("events").add({
        "title": titleController.text.trim(),
        "start": eventStart.value,
        "end": eventEnd.value,
        "participants": participants,
        "created_by": currentUid,
        "created_at": FieldValue.serverTimestamp(),
      });

      ToastService.success(
        "All done! Your event just made the calendar happier",
      );

      //Clearing form when done
      titleController.clear();
      eventStart.value = null;
      eventEnd.value = null;
    } catch (e) {
      ToastService.error("Couldn’t save your event. Give it another go!");
    }
  }
}
