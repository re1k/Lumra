import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/Homepage/Calendar/addEventController.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/theme/custom_themes/text_theme.dart';
import 'package:intl/intl.dart';

class AddEventView extends StatelessWidget {
  AddEventView({super.key});

  final AddEventController controller = Get.put(AddEventController());

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

            // Start Date & Time
            Obx(() {
              final start = controller.startDate.value;
              final startText = start != null
                  ? DateFormat('yyyy-MM-dd HH:mm').format(start)
                  : 'Select Start Date & Time';
              return GestureDetector(
                onTap: () => controller.pickDate(isStart: true),
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
                    children: [
                      Text(startText),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: BSizes.SpaceBtwSections),

            // End Date & Time
            Obx(() {
              final end = controller.endDate.value;
              final endText = end != null
                  ? DateFormat('yyyy-MM-dd HH:mm').format(end)
                  : 'Select End Date & Time';
              return GestureDetector(
                onTap: () => controller.pickDate(isStart: false),
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
                    children: [Text(endText), const Icon(Icons.calendar_today)],
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



          ],
        ),
      ),
    );
  }
}
