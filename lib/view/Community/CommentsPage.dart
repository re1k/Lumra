import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumra_project/controller/Community/PostController.dart';
import 'package:lumra_project/model/community/comments.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/theme/custom_themes/appbar_theme.dart';
import 'package:lumra_project/view/Community/communityWidgets/CommentView.dart';
import 'package:lumra_project/view/Community/communityWidgets/addCommentView.dart'; // <- your new comment sheet
import 'package:lumra_project/utils/customWidgets/custom_dialog.dart';

class CommentsPage extends StatefulWidget {
  final String postId;
  final String postUserName;

  const CommentsPage({
    super.key,
    required this.postId,
    required this.postUserName,
  });

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  late PostControllerX controller;

  @override
  void initState() {
    super.initState();

    /// Make sure controller exists
    if (!Get.isRegistered<PostControllerX>()) {
      controller = Get.put(PostControllerX(FirebaseFirestore.instance));
    } else {
      controller = Get.find<PostControllerX>();
    }

    /// Start listening for comments
    controller.listenToComments(widget.postId);
  }

  void handleReport(Comment comment) {
    //controller.reportComment(widget.postId, comment.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BColors.lightGrey,
      body: Stack(
        children: [
          /// MAIN COLUMN (header + list)
          Column(
            children: [
              /// HEADER
              BAppBarTheme.createHeader(
                context: context,
                title: "Comments",
                subtitle: "for " + widget.postUserName + "'s post",
                showBackButton: true,
                onBackPressed: () => Navigator.pop(context),
              ),

              /// COMMENTS LIST
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 12,
                    left: BSizes.defaultSpace,
                    right: BSizes.defaultSpace,
                  ),
                  child: Transform.translate(
                    offset: const Offset(0, -20), // negative Y moves up
                    child: CommentsListView(
                      onReport: handleReport,
                      postId: widget.postId,
                      isShrinkWrap: false,
                      scrollPhysics: const BouncingScrollPhysics(),
                    ),
                  ),
                ),
              ),
            ],
          ),

          /// Scrollable posts list

          /// FLOATING ADD-COMMENT BUTTON
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
                tooltip: 'Add a comment',
                icon: const Icon(
                  Icons.add_comment_outlined,
                  color: BColors.primary,
                  size: BSizes.iconMd + 5,
                ),
                onPressed: () async {
                  final canPost = await controller.checkAndResetBanIfNeeded();
                  if (!canPost) {
                    final remainingDays = await controller
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
  backgroundColor: BColors.white, // modal background
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(32),
    ),
  ),
  builder: (context) => WillPopScope(
    onWillPop: () async {
      if (controller.contentController.text.length >= 70) {
        bool exit = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: BColors.white, // dialog background
            title: const Text("Confirm Exit"),
            content: const Text(
              "You have typed a lot of content. Are you sure you want to exit?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: BColors.black, // button color
                  
                ),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: BColors.white, // button color
                  backgroundColor: BColors.primary, 
                ),
                child: const Text("Exit"),
              ),
            ],
          ),
        );
        return exit ?? false;
      }
      return true;
    },
    child: FractionallySizedBox(
      heightFactor: 0.80,
        child: AddCommentView(
                        promptMessage:
                            'Write a comment and pass on something helpful!',
                        postId: widget.postId,
                      ),
    ),
  ),
).whenComplete(() {
  controller.contentController.clear();
  controller.updateFormValidity();
});
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
