import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/Community/PostController.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/theme/custom_themes/text_theme.dart';
import 'package:lumra_project/view/Community/communityWidgets/addPostView.dart';
import 'package:lumra_project/view/Community/communityWidgets/postView.dart';


class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  late final PostControllerX postController;

  @override
  void initState() {
    super.initState();
    // Initialize PostControllerX only if it's not already in memory
    postController = Get.isRegistered<PostControllerX>()
        ? Get.find<PostControllerX>()
        : Get.put(
            PostControllerX(
              FirebaseFirestore.instance,
              Get.find<AuthController>().currentUser!.uid,
            ),
            permanent: true,
          );

    // ✅ You can trigger post fetching here if needed
    postController.fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BColors.white,
      appBar: AppBar(
        backgroundColor:BColors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text("Community"),
        titleTextStyle: BTextTheme.lightTextTheme.headlineMedium,
      ),
      body: SafeArea(
        child: PostView(),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: BSizes.SpaceBtwItems,
        ),
        child: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: BColors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              builder: (context) => FractionallySizedBox(
                heightFactor: 0.80,
                child: AddPostView(
                  promptMessage:
                      "Share a tip, experience, or resource that has helped you manage ADHD. Your insight might help someone else!",
                ),
              ),
            ).whenComplete(() {
              // Reset input field when the sheet closes
              postController.contentController.clear();
              // Reset form validity
              postController.updateFormValidity();
            });
          },
          backgroundColor: BColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              BSizes.moreRoundedRaduis,
            ),
          ),
          child: const Icon(
            Icons.edit,
            color: BColors.white,
            size: BSizes.iconMd,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

