import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/Homepage/Calendar/addEventController.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/theme/custom_themes/text_theme.dart';

class AddEventView extends StatelessWidget {
  AddEventView({super.key});
  final authContoller = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    // Directly get the controller from GetX
    final AddEventController controller = Get.put(
      AddEventController(
        FirebaseFirestore.instance,
        authContoller.currentUser!.uid,
      ),
    );
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
        toolbarHeight: 35,
      ),

      body: Padding(
        padding: EdgeInsets.only(
          left: BSizes.defaultSpace,
          right: BSizes.defaultSpace,
          top: BSizes.defaultSpace,
          bottom: BSizes.sm,
        ), // clear margin around content
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ------------------EVENT TITLE------------------ //

              //THE LABEL
              Text("Title", style: BTextTheme.lightTextTheme.titleSmall),

              // Distance between the label and the feild
              const SizedBox(height: 8),

              //THE FEILD
              Obx(() {
                final hasError =
                    controller.titleError.value != null &&
                    controller.titleFieldTouched.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller.titleController,
                      // this method i made in my ontroller to watch out for input validity for turning red
                      onChanged: controller.updateTitle,

                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            BSizes.inputFieldRadius,
                          ),
                          borderSide: BorderSide(
                            color: controller.titleError.value != null
                                ? BColors.error
                                : BColors.darkGrey,
                          ),
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            BSizes.inputFieldRadius,
                          ),
                          borderSide: BorderSide(
                            color: controller.titleError.value != null
                                ? BColors.error
                                : BColors.darkGrey,
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            BSizes.inputFieldRadius,
                          ),
                          borderSide: BorderSide(
                            color: controller.titleError.value != null
                                ? BColors.error
                                : BColors.darkGrey,
                            width: 1.3,
                          ),
                        ),
                        errorText: null, // remove error text if correct feild
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),

                    // Error message below the field
                    if (hasError)
                      Padding(
                        padding: const EdgeInsets.only(
                          right: 0,
                          top: 4,
                          left: 8,
                        ),
                        child: Text(
                          controller.titleError.value!,
                          style: const TextStyle(
                            color: BColors.error,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                );
              }),

              const SizedBox(height: BSizes.spaceBtwinputFields),

              // ------------------ Start Time ------------------ //
              Text("Start time", style: BTextTheme.lightTextTheme.titleSmall),
              const SizedBox(height: 8),

              //Obx is from GetX. It automatically rebuilds this widget whenever the reactive variable changes (eventStart).
              Obx(() {
                final startTimestamp = controller.eventStart.value;
                //this is just for UI, to make time human readable not timeStamp
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
                      border: Border.all(
                        color: BColors.darkGrey,
                      ), // border color
                      borderRadius: BorderRadius.circular(
                        BSizes.inputFieldRadius,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(startText),
                        const Icon(Icons.access_time),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: BSizes.SpaceBtwItems),

              // ------------------ End Time ------------------ //
              Text("End time", style: BTextTheme.lightTextTheme.titleSmall),
              const SizedBox(height: 8),

              Obx(() {
                final endTimestamp = controller.eventEnd.value;
                final endText = endTimestamp != null
                    ? TimeOfDay.fromDateTime(
                        endTimestamp.toDate(),
                      ).format(Get.context!)
                    : 'Select End Time';
                final hasError = controller.endError.value != null;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => controller.pickTime(isStart: false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: hasError ? BColors.error : BColors.darkGrey,
                          ),
                          borderRadius: BorderRadius.circular(
                            BSizes.inputFieldRadius,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(endText),
                            const Icon(Icons.access_time),
                          ],
                        ),
                      ),
                    ),

                    // Error message below the field
                    if (hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 8),
                        child: Text(
                          controller.endError.value!,
                          style: const TextStyle(
                            color: BColors.error,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                );
              }),

              const SizedBox(height: BSizes.appBarHeight),

              // ------------------ ADD BUTTON ------------------ //
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isFormValid.value
                        ? () async {
                            // Make sure validation runs one last time
                            if (controller.validateForm()) {
                              await controller.addEventToFirebase();
                              Navigator.pop(context); // closes the view
                            }
                          }
                        : null, // disables button if form not valid // null disables the button
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: Colors.white, // keep icon/text white
                      disabledForegroundColor: Colors.white.withOpacity(0.6),
                    ),

                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check),
                        const SizedBox(width: 8),
                        Text(
                          "Add",
                          style: BTextTheme.darkTextTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
