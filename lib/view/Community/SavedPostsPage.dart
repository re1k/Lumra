import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/Community/PostController.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/custom_themes/appbar_theme.dart';
import 'package:lumra_project/theme/custom_themes/text_theme.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/view/Community/communityWidgets/postView.dart';

/// SavedPostsPage
/// ----------------
/// Displays the posts that the user has saved/bookmarked.
class SavedPostsPage extends StatelessWidget {
  const SavedPostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Make sure the PostControllerX is available
    if (!Get.isRegistered<PostControllerX>()) {
      Get.put(
        PostControllerX(
          FirebaseFirestore.instance,
          Get.find<AuthController>().currentUser!.uid,
        ),
      );
    }
    return Scaffold(
   backgroundColor: BColors.lightGrey,
    body: Stack(
      children: [
        Column(
          children: [
            // Custom header
            BAppBarTheme.createHeader(
              context: context,
              title: 'Saved Posts',
              showBackButton: true,
              onBackPressed: () => Navigator.pop(context),
            ),
            // Page content
            Expanded(
            child: Padding(
            padding: const EdgeInsets.only(bottom: 30), // distance from bottom
            child: PostView(showSaved: true)),
              ),
      ]),
          ],
        ),
    );
  }
}
