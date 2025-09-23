import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/Homepage/Calendar/addEventController.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/theme/custom_themes/text_theme.dart';
import 'package:intl/intl.dart';

class AddEventView extends StatelessWidget {
  
  AddEventView({super.key});

  // Directly get the controller from GetX
  final AddEventController controller = Get.put(
    AddEventController(FirebaseFirestore.instance, FirebaseAuth.instance.currentUser!.uid),
  );

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: BColors.white),
          onPressed: () {
            Navigator.pop(context); // goes back to the previous screen
          },
        ),
        title: Text("Add Event"),
        titleTextStyle: BTextTheme.lightTextTheme.headlineLarge,
        backgroundColor: Colors.white,
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(
          BSizes.defaultSpace,
        ), // clear margin around content
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: BSizes.SpaceBtwSections),

            // Event Title Input
            TextField(
              controller: controller.titleController,
              decoration: const InputDecoration(
                labelText: 'Event Title',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),

            const SizedBox(height: BSizes.SpaceBtwSections),

            // Start Time
            //Obx is from GetX. It automatically rebuilds this widget whenever the reactive variable changes (eventStart).
            Obx(() {
              final startTimestamp = controller.eventStart.value;

              //this is just for UI, to make time humen readable not timeStamp
              final startText = startTimestamp != null 
                  ? TimeOfDay.fromDateTime(
                      startTimestamp.toDate(),
                    ).format(Get.context!)
                  : 'Select Start Time';

              return GestureDetector(
                //To show the TimePicker when user Clicks
                onTap: () => controller.pickTime(isStart: true),

                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey), // border color
                    borderRadius: BorderRadius.circular(14), // rounded corners
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(startText), const Icon(Icons.access_time)],
                  ),
                ),
              );
            }),

            const SizedBox(height: BSizes.SpaceBtwSections),

            // End Time
            Obx(() {
              final endTimestamp = controller.eventEnd.value;
              final endText = endTimestamp != null
                  ? TimeOfDay.fromDateTime(
                      endTimestamp.toDate(),
                    ).format(Get.context!)
                  : 'Select End Time';

              return GestureDetector(
                onTap: () => controller.pickTime(isStart: false),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(endText), const Icon(Icons.access_time)],
                  ),
                ),
              );
            }),

            const SizedBox(height: BSizes.appBarHeight),

            // Add Event Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.find<AddEventController>().addEventToFirebase();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  "Save",
                  style: BTextTheme.darkTextTheme.headlineSmall,
                ),
              ),
            ),

            const SizedBox(height: BSizes.SpaceBtwSections),
 /*
            // Bottom Image
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,

              child: Center(
                child: Image.asset(
                  'assets/images/goals.png',
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
            */

          ],
        ),
      ),
    );
  }
}
