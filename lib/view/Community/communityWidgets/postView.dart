import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/Community/PostController.dart';
import 'package:lumra_project/model/community/communityModel.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/theme/custom_themes/text_theme.dart';

/// PostView
/// ----------------
/// This widget displays the community posts feed.
/// Uses a single PostControllerX for all posts & comments
class PostView extends StatelessWidget {
  final bool showSaved;
  final PostControllerX controller = Get.find<PostControllerX>();

  PostView({super.key, this.showSaved = false});

  @override
  Widget build(BuildContext context) {
  return Obx(() {

    //if from AccountPage, show saved
    final postList = (!showSaved) ? controller.posts: controller.savedPosts ;

   if (postList.isEmpty) {
    return const Center(child: Text('No posts yet. . .'));
   }

    return Padding(
      padding: EdgeInsets.all(BSizes.defaultSpace),
      child: ListView.separated(
        itemCount: postList.length,
        separatorBuilder: (_, __) => SizedBox(height: BSizes.SpaceBtwItems),
        itemBuilder: (context, index) => _postCard(postList[index]),
      ),
    );
  });
  }

  /// Builds a single post card with up to 2 comments
  Widget _postCard(Post post) {

    return Container(
      margin: const EdgeInsets.symmetric(vertical: BSizes.sm),
      padding: const EdgeInsets.all(BSizes.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(BSizes.moreRoundedRaduis),
        border: Border.all(color: BColors.secondry, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.25),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _postHeader(post),
          const SizedBox(height: BSizes.sm),
          _postContent(post),
          const SizedBox(height: BSizes.sm),
          _postActionButtons(post),
        ],
      ),
    );
  }

  Widget _postHeader(Post post) {
    const double avatarDiameter = 40;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(BSizes.sm),
              child: Container(
                width: avatarDiameter,
                height: avatarDiameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: BColors.secondry, // border color
                    width: 1, // border thickness
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/Avatar.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(width: BSizes.sm),
            Text(
              '${post.userName}',
              style: BTextTheme.lightTextTheme.labelLarge,
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.report_outlined, size: BSizes.iconXMd),
          onPressed: () {},
          color: Colors.grey[800],
          tooltip: 'Report',
        ),
      ],
    );
  }

  Widget _postContent(Post post) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BSizes.sm,
        vertical: BSizes.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(post.content),
          SizedBox(height: BSizes.xs),
          Text(
            'Posted ${post.createdAt.toDate().toLocal().toString().split(' ')[0]}',
            style: BTextTheme.lightTextTheme.labelMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: BSizes.sm),
          Divider(indent: 0.5, endIndent: 0.5, color: BColors.grey),
        ],
      ),
    );
  }

  Widget _postActionButtons(Post post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BSizes.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(),
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.comment_outlined,
                  size: BSizes.iconXMd,
                ),
                onPressed: () {},
                color: Colors.grey[800],
                tooltip: 'Comment',
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border, size: BSizes.iconXMd),
                onPressed: () {},
                color: Colors.grey[800],
                tooltip: 'Like',
              ),

              Obx(() {
                final isSaved = controller.isPostSaved(post.id);
                final isShowingCheck = controller.isShowingCheck(post.id);

                return GestureDetector(
                  onTap: () async {
                    if (isSaved) {
                      await controller.unsavePost(post.id);
                    } else {
                      await controller.savePost(post);
                      controller.showBookmarkCheck(
                        post.id,
                      ); // triggers check animation
                    }
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: isShowingCheck
                        ? Icon(
                            Icons.check,
                            key: ValueKey('check_${post.id}'),
                            color: BColors.buttonPrimary,
                            size: BSizes.iconXMd + 2,
                          )
                        : Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            key: ValueKey('bookmark_${post.id}'),
                            color: isSaved
                                ? BColors.buttonPrimary
                                : Colors.grey[800],
                            size: BSizes.iconXMd,
                          ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
