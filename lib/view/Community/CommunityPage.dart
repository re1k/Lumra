import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/Community/PostController.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/theme/custom_themes/appbar_theme.dart';
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
        : Get.put(PostControllerX(FirebaseFirestore.instance), permanent: true);
    //post fetching here
    postController.fetchPosts();
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BColors.lightGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          child:Column(
          children: [
           SizedBox(
  width: double.infinity,
  child: Stack(
    clipBehavior: Clip.none,
    children: [
      /// Header stays at the top
       Transform.translate(
        offset: const Offset(0, -23), // push upward by 10 px
        child: BAppBarTheme.createHeader(
          context: context,
          title: 'Community',
          subtitle: "Connect with others",
        ),
      ),
      /// Add post button absolutely positioned
      Positioned(
        top: BSizes.lg+8,   // distance from the top of the screen
        right: 24, // adjust as needed
        child: Container(
          decoration: BoxDecoration(
            color: BColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            tooltip: 'Create a post',
            icon: const Icon(
              Icons.edit,
              color: BColors.primary,
              size: BSizes.iconLg,
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: BColors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                builder: (context) => FractionallySizedBox(
                  heightFactor: 0.80,
                  child: AddPostView(
                    promptMessage:
                        "Share a tip, experience, or resource that has helped. Your insight might help someone else!",
                  ),
                ),
              ).whenComplete(() {
                postController.contentController.clear();
                postController.updateFormValidity();
              });
            },
          ),
        ),
      ),
    ],
  ),
)
                
                ,

           Padding(
            padding: EdgeInsets.fromLTRB(
              BSizes.lg,
              0,
              BSizes.lg,
              BSizes.lg + 80, // space for bottom nav bar
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // POST LIST (scrollable with header)
                PostView(),
              ],
            ),
          ),

          ],
         
        ),
      ),
    )
    );
  }


}