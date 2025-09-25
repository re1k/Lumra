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

  // Validation state for my view
  var titleFieldTouched = true.obs;
  var titleError = RxnString();
  var startError = RxnString();
  var endError = RxnString();

  var isFormValid = false.obs;

  var isEventAdded = false.obs;

  AddEventController(this.db, this.currentUid);

  //to get the date from the calander controller
  @override
  void onInit() {
    super.onInit();
    // register CalendarController if needed
    if (!Get.isRegistered<CalendarController>()) {
      calendarController = Get.put(
        CalendarController(this.db, this.currentUid),
      );
    } else {
      calendarController = Get.find<CalendarController>();
    }
  }

  // ------------------ Title validate ------------------ //
  void updateTitle(String value) {
    titleFieldTouched.value = true;
    validateTitle(value);
    updateFormValidity();
  }

  void validateTitle(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      titleError.value = "Title is required";
    } else if (text.length < 3) {
      titleError.value = "Title must be at least 3 characters";
    } else {
      titleError.value = null; //when error no there, dont make red
    }
  }


  // ------------------ Time validate ------------------ //

  //whenever start or end changes
  void validateTimes() {
    if (eventStart.value == null) {
      startError.value = "Start time is required";
    } else {
      startError.value = null;
    }
    if (eventEnd.value == null) {
      endError.value = "End time is required";
    } else if (eventStart.value != null &&
        !eventEnd.value!.toDate().isAfter(eventStart.value!.toDate())) {
      endError.value = "End time must be after start time";
    } else {
      endError.value = null; // valid
    }
  }

  void updateFormValidity() {
    isFormValid.value =
        titleError.value == null &&
        startError.value == null &&
        endError.value == null;
  }

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
      validateTimes(); // run validation whenever a time is picked
      updateFormValidity();
    }
  }

  // ------------------ Form ------------------ //
  bool validateForm() {
  // Mark title as touched so error shows
  titleFieldTouched.value = true;

    validateTitle(titleController.text);
    validateTimes();

    // Update form validity (for the button)
    updateFormValidity();

    return titleError.value == null &&
        startError.value == null &&
        endError.value == null;
  }

  // Now adding the event
  Future<void> addEventToFirebase() async {
    if (!validateForm()) return;

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
      isEventAdded.value = true;

      //Clearing form when done
      titleController.clear();
      eventStart.value = null;
      eventEnd.value = null;
    } catch (e) {
      ToastService.error("Couldn’t save your event. Give it another go!");
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    isEventAdded.value = false; // reset
    super.onClose();
  }
}
