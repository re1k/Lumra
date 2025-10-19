import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/Community/PostController.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/theme/custom_themes/text_theme.dart';

class AddPostView extends StatelessWidget {
  final String promptMessage; //to differ in the careGiver and at ADHD user

  AddPostView({super.key, required this.promptMessage});

  final authController = Get.find<AuthController>();
  final TextEditingController contentController = TextEditingController();
  final PostControllerX postController = Get.find<PostControllerX>();

  // Observing validity of the input field
  final RxBool isValid = false.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Create Post"),
        titleTextStyle: BTextTheme.lightTextTheme.headlineLarge,
        backgroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: 35,
      ),

      body: Padding(
        padding: const EdgeInsets.all(BSizes.defaultSpace),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [


             
                Text(promptMessage, style: BTextTheme.lightTextTheme.labelSmall),
              


              const SizedBox(height: BSizes.SpaceBtwSections-5),
                /// Warning note
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  "* Note that posts cannot exceed 180 charaters or be empty",
                  style: TextStyle(
                    color: BColors.darkGrey, // correct way to set text color
                    fontSize: 12,
                  ),
                ),
              ),
               const SizedBox(height: BSizes.sm),
               
              TextField(
                controller: postController.contentController,
                maxLines: 6,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(180), // LIMIT 180
                ],
                onChanged: (value) { 
                  postController.currentLength.value = value.length;// counts spaces too
                  postController.updateFormValidity();},
                decoration: InputDecoration(
                  hintText: "What's on your mind?",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      BSizes.inputFieldRadius,
                    ),
                    borderSide: BorderSide(color: BColors.secondry),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      BSizes.inputFieldRadius,
                    ),
                    borderSide: BorderSide(color: BColors.secondry),
                  ),
                ),
              ),

              const SizedBox(height: BSizes.sm),
             // Reactive remaining characters
              Obx(() {
                final remaining = 180 - postController.currentLength.value;
                final text = remaining <= 0
                    ? "No characters left"
                    : "$remaining characters left";
                return Align(
                  alignment: Alignment.centerRight, // aligns text to the right
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: BColors.primary,
                      fontSize: 12,
                    ),
                  ),
                );
              }),
            
              const SizedBox(height: BSizes.SpaceBtwSections + 20),

              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        postController.isFormValid.value &&
                            !postController.isLoading.value
                        ? () async {
                            await postController.addPost();
                            if (!postController.isLoading.value) {
                              Navigator.pop(context);
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white.withOpacity(0.6),
                    ),
                    child: postController.isLoading.value
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Loading...",
                                style: BTextTheme.darkTextTheme.headlineSmall,
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send),
                              const SizedBox(width: 8),
                              Text(
                                "Post",
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
