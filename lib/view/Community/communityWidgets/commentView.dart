import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/Community/PostController.dart';
import 'package:lumra_project/model/community/comments.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/theme/custom_themes/text_theme.dart';
import 'package:lumra_project/utils/customWidgets/toastservice.dart';

/// ----------------------
/// Reactive Comments List
/// ----------------------
class CommentsListView extends StatelessWidget {
  final PostControllerX controller = Get.find<PostControllerX>();
  final Function(Comment) onReport;
  final bool isShrinkWrap;
  final ScrollPhysics scrollPhysics;
  final String postId;

  CommentsListView({
    super.key,
    required this.onReport,
    required this.postId,
    this.isShrinkWrap = true,
    this.scrollPhysics = const NeverScrollableScrollPhysics(),
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      //Decide Which lisrt to display
      final comments = controller.commentsForPost(postId);

      // Handle empty state
      if (comments.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.only(
              // to make centerd
              bottom: 45,
            ),
            child: Image.asset(
              'assets/images/NoComments.png',
              width: 260,
              height: 260,
              fit: BoxFit.contain,
            ),
          ),
        );
      }

      return ListView.separated(
        itemCount: comments.length,
        shrinkWrap: isShrinkWrap,
        separatorBuilder: (_, __) => SizedBox(height: BSizes.SpaceBtwItems),
        itemBuilder: (context, index) {
          final comment = comments[index];
           return _commentCard(context, comment);}
      );
    });
  }

Widget _commentCard(BuildContext context, Comment comment) {
  const double avatarSize = 30; // smaller profile photo
  final reportNotifier = ValueNotifier<bool>(false);

  return Container(
    margin: const EdgeInsets.only(bottom: BSizes.sm),
    padding: const EdgeInsets.all(BSizes.sm),
    decoration: BoxDecoration(
      color: BColors.white,
      borderRadius: BorderRadius.circular(BSizes.cardRadiusLg),
      border: Border.all(color: BColors.secondry),
      boxShadow: const [
        BoxShadow(
          color: Color(0x11000000),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Header: profile + username + action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Avatar + username
            Row(
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: BColors.secondry, width: 1),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/AvatarSimple.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: BSizes.sm),
                Text(
                  comment.userName,
                  style: BTextTheme.lightTextTheme.labelLarge,
                ),
              ],
            ),

            // RIGHT: Trash if mine, flag if someone else's
            comment.userId == controller.currentUid
                ? IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: BColors.primary,
                      size: BSizes.iconMd - 2,
                    ),
                    tooltip: 'Delete comment',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          title: const Text('Delete'),
                          content: const Text(
                              'Are you sure you want to delete this comment?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: BColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text(
                                'Confirm',
                                style: TextStyle(
                                    fontFamily: 'K2D', fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await controller.deleteComment(
                            postId, comment.id.toString());
                      }
                    },
                  )
                : IconButton(
                    icon: ValueListenableBuilder<bool>(
                      valueListenable: reportNotifier,
                      builder: (context, isReporting, child) {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: isReporting
                              ? Icon(
                                  Icons.flag,
                                  key: ValueKey('reporting_${comment.id}'),
                                  color: BColors.error,
                                  size: BSizes.iconMd - 2,
                                )
                              : Icon(
                                  Icons.flag_outlined,
                                  key: ValueKey('unreported_${comment.id}'),
                                  color: BColors.primary,
                                  size: BSizes.iconMd - 2,
                                ),
                        );
                      },
                    ),
                    tooltip: 'Report comment',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          title: const Text('Report'),
                          content: const Text(
                              'Are you sure you want to report this comment?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: BColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text(
                                'Confirm',
                                style: TextStyle(
                                    fontFamily: 'K2D', fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        reportNotifier.value = true;
                        await controller.reportComment(
                            postId, comment.id.toString());
                        Future.delayed(const Duration(milliseconds: 600), () {
                          reportNotifier.value = false;
                        });
                      }
                    },
                  ),
          ],
        ),

        const SizedBox(height: BSizes.sm),

        /// Comment content
        Padding(
          padding: const EdgeInsets.only(left: BSizes.sm),
          child: Text(
            comment.content,
            style: BTextTheme.lightTextTheme.bodyMedium,
          ),
        ),

        const SizedBox(height: BSizes.md),

        /// Posted date
        Padding(
          padding: const EdgeInsets.only(left: BSizes.sm),
          child: Text(
            'Commented ${comment.createdAt.toDate().toLocal().toString().split(" ")[0]}',
            style: BTextTheme.lightTextTheme.labelMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: BColors.darkGrey,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );
}
}
