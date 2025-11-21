import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/Account/UserController.dart';
import 'package:lumra_project/controller/Community/PostController.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/theme/custom_themes/appbar_theme.dart';
import 'package:lumra_project/view/ChatBootADHD/ChatBotWidget.dart';
import 'package:lumra_project/view/Community/communityWidgets/addPostView.dart';
import 'package:lumra_project/view/Community/communityWidgets/postView.dart';
import 'package:lumra_project/utils/customWidgets/custom_dialog.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  late final PostControllerX postController;
  late final UserController _userController;
  final authContoller = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    // Initialize PostControllerX only if it's not already in memory
    postController = Get.isRegistered<PostControllerX>()
        ? Get.find<PostControllerX>()
        : Get.put(PostControllerX(FirebaseFirestore.instance), permanent: true);
    //post fetching here
    //  postController.fetchPosts();
    if (!Get.isRegistered<UserController>()) {
      _userController = Get.put(UserController(FirebaseFirestore.instance));
      _userController.init();
    } else {
      _userController = Get.find<UserController>();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BColors.lightGrey,
      body: Stack(
        children: [
          // Scrollable content
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: BAppBarTheme.createHeader(
                    context: context,
                    title: 'Community',
                    subtitle: "Connect with others",
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    BSizes.lg,
                    0,
                    BSizes.lg,
                    BSizes.lg + 80, // space for bottom nav bar
                  ),
                  child: Transform.translate(
                    offset: const Offset(0, -16), // moves content 20 pixels up
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [PostView()],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating Add Post button outside scroll
          Positioned(
            top: 55,
            right: 24,
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
                  Icons.add,
                  color: BColors.primary,
                  size: BSizes.iconLg,
                ),
                onPressed: () async {
                  final canPost = await postController
                      .checkAndResetBanIfNeeded();
                  if (!canPost) {
                    final remainingDays = await postController
                        .getRemainingBanDays();
                    if (remainingDays != null) {
                      final dayText = remainingDays == 1 ? 'day' : 'days';
                      CustomDialog.showCloseOnly(
                        context,
                        title: "Posting Temporarily Disabled",
                        message:
                            "Posting has been disabled due to your recent posting activity.\nYou can post again in $remainingDays $dayText.",
                      );
                    }
                    return;
                  }

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
                            "Share a tip, experience, or resource that has helped you. Your insight might help someone else!",
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

          if (_userController.role == 'adhd')
            const ChatBotWidget(role: 'adhd')
          else
            const ChatBotWidget(role: 'caregiver'),
        ],
      ),
    );
  }
}
