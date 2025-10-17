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
      final postList = (!showSaved) ? controller.posts : controller.savedPosts;
if (postList.isEmpty) {
  return Center(
    child: Image.asset(
      !showSaved 
          ? 'assets/images/NoPosts.png' 
          : 'assets/images/NoSavedPosts.png',
      width: 300,  // Adjust size as needed
      height: 300,
      fit: BoxFit.contain,
    ),
  );
}
      return ListView.separated(
        itemCount: postList.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (_, __) => SizedBox(height: BSizes.SpaceBtwItems),
        itemBuilder: (context, index) => _postCard(postList[index]),
      );
    });
  }

  /// Builds a single post card with up to 2 comments
  Widget _postCard(Post post) {
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
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _postHeader(post),
          const SizedBox(height: BSizes.sm),
          _postContent(post),
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
          icon: const Icon(Icons.flag_outlined, size: BSizes.iconMd),
          onPressed: () {},
          color: BColors.darkGrey,
          tooltip: 'Report',
        ),
      ],
    );
  }

  Widget _postContent(Post post) {
    return Padding(
      padding: const EdgeInsets.only(
        top: BSizes.xs,
        bottom: 0,
        left: BSizes.sm,
        right: BSizes.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(post.content),
          SizedBox(height: BSizes.sm),
          Text(
            'Posted ${post.createdAt.toDate().toLocal().toString().split(' ')[0]}',
            style: BTextTheme.lightTextTheme.labelMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: BSizes.xs),
          Divider(indent: 0.5, endIndent: 0.5, color: BColors.grey),
        ],
      ),
    );
  }

  Widget _postActionButtons(Post post) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.favorite_border, size: BSizes.iconMd),
          onPressed: () {},
          color: BColors.darkGrey,
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
                      size: BSizes.iconMd + 2,
                    )
                  : Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      key: ValueKey('bookmark_${post.id}'),
                      color: isSaved ? BColors.buttonPrimary : BColors.darkGrey,
                      size: BSizes.iconMd,
                    ),
            ),
          );
        }),
        IconButton(
          icon: const Icon(Icons.comment_outlined, size: BSizes.iconMd - 1.5),
          onPressed: () {},
          color: BColors.darkGrey,
          tooltip: 'Comment',
        ),
      ],
    );
  }
}
