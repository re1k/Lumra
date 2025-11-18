import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/Community/PostController.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';
import 'package:lumra_project/model/community/communityModel.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/theme/custom_themes/text_theme.dart';

class AddPostView extends StatefulWidget {
  final String promptMessage; //to differ in the careGiver and at ADHD user
  final Post? postToEdit; // nullable, only for editing
  final bool isEdit;

  const AddPostView({
    super.key,
    required this.promptMessage,
    this.postToEdit,
    this.isEdit = false,
  });

  @override
  State<AddPostView> createState() => _AddPostViewState();
}

class _AddPostViewState extends State<AddPostView> {
  final authController = Get.find<AuthController>();
  final TextEditingController contentController = TextEditingController();
  final PostControllerX postController = Get.find<PostControllerX>();

  // Observing validity of the input field
  final RxBool isValid = false.obs;

  @override
  void initState() {
    super.initState();
    postController.resetFormState();
    // If editing, prefill content
    if (widget.isEdit && widget.postToEdit != null) {
      postController.contentController.text = widget.postToEdit!.content;
      postController.currentLength.value = widget.postToEdit!.content.length;
      postController.updateFormValidity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.isEdit ? "Edit Post" : "Create Post"),
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
              Text(
                widget.promptMessage,
                style: BTextTheme.lightTextTheme.labelSmall,
              ),

               SizedBox(height: widget.isEdit ? 0 : BSizes.SpaceBtwSections - 15),

              /// Warning note
              Padding(
                padding: EdgeInsets.only(
                  left: 4,
                  right: 4,
                  bottom: 4,
                  top: widget.isEdit ? 0 :10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline, // or Icons.warning_amber_rounded
                      color: BColors.darkGrey,
                      size: 13,
                    ),
                    const SizedBox(width: 4), // spacing between icon and text
                    Expanded(
                      child: Text(
                        "Note that posts cannot exceed 180 characters, be empty or only contain special characters.",
                        style: TextStyle(color: BColors.darkGrey, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: BSizes.sm),

              Obx(() {
                final shouldShowError = postController.hasInteracted.value;
                final hasError =
                    shouldShowError &&
                    (postController.hasRestrictedContent.value ||
                        postController.contentError.value != null);
                final errorText = shouldShowError
                    ? (postController.hasRestrictedContent.value
                          ? "Your post contains restricted content."
                          : postController.contentError.value)
                    : null;

                return TextField(
                  controller: postController.contentController,
                  maxLines: 6,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(180), // LIMIT 180
                  ],
                  onChanged: (value) {
                    postController.currentLength.value =
                        value.length; // counts spaces too
                    postController.updateFormValidity();
                  },
                  decoration: InputDecoration(
                    hintText: "What's on your mind?",
                    errorText: errorText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        BSizes.inputFieldRadius,
                      ),
                      borderSide: BorderSide(
                        color: hasError ? BColors.error : BColors.secondry,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        BSizes.inputFieldRadius,
                      ),
                      borderSide: BorderSide(
                        color: hasError ? BColors.error : BColors.secondry,
                        width: hasError ? 2 : 1,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        BSizes.inputFieldRadius,
                      ),
                      borderSide: const BorderSide(
                        color: BColors.error,
                        width: 1,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        BSizes.inputFieldRadius,
                      ),
                      borderSide: const BorderSide(
                        color: BColors.error,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }),

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
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white70,
                      backgroundColor: BColors.primary,
                    ),
                    onPressed:
                        postController.isFormValid.value &&
                            !postController.isLoading.value
                        ? () async {
                            bool success = false;

                            if (widget.isEdit && widget.postToEdit != null) {
                              success = await postController.updatePost(
                                widget.postToEdit!.id,
                                postController.contentController.text.trim(),
                              );
                            } else {
                              success = await postController.addPost(context);
                            }

                            if (success) Navigator.pop(context);
                          }
                        : null,
                    child: postController.isLoading.value
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text("Loading..."),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(widget.isEdit ? Icons.edit : Icons.send),
                              const SizedBox(width: 8),
                              Text(widget.isEdit ? "Update" : "Post"),
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
