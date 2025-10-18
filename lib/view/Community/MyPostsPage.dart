import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/Community/PostController.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/theme/custom_themes/appbar_theme.dart';
import 'package:lumra_project/view/Community/communityWidgets/postView.dart';

class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  late PostControllerX controller;

  @override
  void initState() {
    super.initState();
    // Make sure the PostControllerX is available
    if (!Get.isRegistered<PostControllerX>()) {
      controller = Get.put(PostControllerX(FirebaseFirestore.instance));
    } else {
      controller = Get.find<PostControllerX>();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BColors.lightGrey,
      body: Stack(
        children: [
          Column(
            children: [
              // Custom header
              BAppBarTheme.createHeader(
                context: context,
                title: 'My Posts',
                showBackButton: true,
                onBackPressed: () => Navigator.pop(context),
              ),

              /// Scrollable posts list
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 12,
                    left: BSizes.defaultSpace,
                    right: BSizes.defaultSpace,
                  ),
                  child: Transform.translate(
                    offset: const Offset(0, -20), // negative Y moves up
                    child: PostView(
                      showUserPosts: true,
                      isShrinkWrap: false,
                      SrollType: const BouncingScrollPhysics(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
