import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/utils/customWidgets/toastservice.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEventController extends GetxController {
  final titleController = TextEditingController();
  Rx<DateTime?> startDate = Rx<DateTime?>(null);
  Rx<DateTime?> endDate = Rx<DateTime?>(null);

  //Function to pick date
  Future<void> pickDate({required bool isStart}) async {
    final initialDate = isStart
        ? startDate.value ?? DateTime.now()
        : endDate.value ?? DateTime.now();

    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: BColors.buttonPrimary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    //PICK TIME
    if (picked != null) {
      // After picking date, pick time
      final time = await showTimePicker(
        context: Get.context!,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: BColors.buttonPrimary, // header color
                onPrimary: Colors.white, // header text color
                onSurface: Colors.black, // body text color
              ),
              timePickerTheme: TimePickerThemeData(
                dayPeriodColor: BColors.accent, // AM/PM background
                dayPeriodTextColor: Colors.black, // AM/PM text
              ),
            ),
            child: child!,
          );
        },
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      //taking the inputs and assign
      if (time != null) {
        final finalDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );

        if (isStart) {
          startDate.value = finalDateTime;
        } else {
          endDate.value = finalDateTime;
        }
      }
    }
  }

  // Validation
  bool validateEvent() {
    if (titleController.text.trim().isEmpty) {
      ToastService.error("Title is required");
      return false;
    }
    if (startDate.value == null) {
      ToastService.error("Start date is required");
      return false;
    }
    if (endDate.value == null) {
      ToastService.error("End date is required");
      return false;
    }
    if (endDate.value!.isBefore(startDate.value!)) {
      ToastService.error("End date cannot be before start date");
      return false;
    }
    return true;
  }

  // Now adding the event
  Future<void> addEventToFirebase() async {
    if (!validateEvent()) return;

    try {
      // Getting current Firebase user ID
      final currentUser = FirebaseAuth.instance.currentUser;
      final userId = currentUser?.uid;

      if (userId == null) {
        ToastService.error("You must be signed in to create an event.");
        return;
      }

      // Fetch the current user document
      final userDoc = await FirebaseFirestore.instance
          .collection("user")
          .doc(userId)
          .get();

      // Extract caregiverId if any
      final userData = userDoc.data();
      final caregiverId = userData?["linkedUserId"];

      //linking the event with the other user
      final participants = [userId];
      if (caregiverId != null && caregiverId.toString().isNotEmpty) {
        participants.add(caregiverId);
      }

      //Add event
      await FirebaseFirestore.instance.collection("events").add({
        "title": titleController.text.trim(),
        "start": startDate.value,
        "end": endDate.value,
        "Participants": participants,
        "created_by": userId,
        "created_at": FieldValue.serverTimestamp(),
      });

      ToastService.success(
        "All done! Your event just made the calendar happier",
      );

      //Clearing form when done
      titleController.clear();
      startDate.value = null;
      endDate.value = null;
    } catch (e) {
      ToastService.error("Couldn’t save your event. Give it another go!");
    }
  }
}
