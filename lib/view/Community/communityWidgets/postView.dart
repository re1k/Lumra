import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/Community/PostController.dart';
import 'package:lumra_project/model/community/comments.dart';
import 'package:lumra_project/model/community/communityModel.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/theme/custom_themes/text_theme.dart';
import 'package:lumra_project/utils/customWidgets/toastservice.dart';
import 'package:lumra_project/view/Community/CommentsPage.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lumra_project/view/Community/communityWidgets/addPostView.dart';

/// PostView
/// This widget displays the community posts feed.
/// Uses a single PostControllerX for all posts & comments
class PostView extends StatelessWidget {
  final bool showSaved;
  final bool showUserPosts;
  final bool isShrinkWrap;
  final ScrollPhysics SrollType;
  final PostControllerX controller = Get.find<PostControllerX>();

  PostView({
    super.key,
    this.showSaved = false,
    this.showUserPosts = false,
    this.isShrinkWrap = true,
    this.SrollType = const NeverScrollableScrollPhysics(),
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      //Decide Which lisrt to display
      final postList;
      if (showUserPosts) {
        postList = controller.userPosts;
      } else if (showSaved) {
        postList = controller.savedPosts;
      } else {
        postList = controller.posts;
      }

      // Handle empty state
      if (postList.isEmpty) {
        String imagePath;
        if (showUserPosts) {
          imagePath = 'assets/images/NoMyPosts.png';
        } else if (showSaved) {
          imagePath = 'assets/images/NoSavedPosts.png';
        } else {
          imagePath = 'assets/images/NoPosts.png';
        }

        return Center(
          child: Padding(
            padding: EdgeInsets.only(
              // to make centerd
              top: imagePath.contains('assets/images/NoPosts.png') ? 130 : 0,
            ),
            child: Image.asset(
              imagePath,
              width: 295,
              height: 295,
              fit: BoxFit.contain,
            ),
          ),
        );
      }

      return ListView.separated(
        itemCount: postList.length,
        shrinkWrap: isShrinkWrap,
        physics: SrollType,
        separatorBuilder: (_, __) => SizedBox(height: BSizes.SpaceBtwItems),
        itemBuilder: (context, index) => _postCard(context, postList[index]),
      );
    });
  }

  /// Builds a single post card
  Widget _postCard(BuildContext context, Post post) {
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
          _postHeader(context, post),
          const SizedBox(height: BSizes.sm),
          _postContent(post),
          _postActionButtons(context, post),
        ],
      ),
    );
  }

  Widget _postHeader(BuildContext context, Post post) {
    const double avatarDiameter = 40;
    final reportNotifier = ValueNotifier<bool>(false);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // LEFT: Avatar + Username
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(BSizes.sm),
              child: Container(
                width: avatarDiameter,
                height: avatarDiameter,
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
            ),
            SizedBox(width: BSizes.sm),
            Text(
              '${post.userName}',
              style: BTextTheme.lightTextTheme.labelLarge,
            ),
          ],
        ),

        // RIGHT: Actions
        if (post.userId == controller.currentUid)
          // My Post: Only Edit/Delete Menu 
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: BColors.primary),
            color: BColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            onSelected: (value) async {
              if (value == 'edit') {
                controller.contentController.text = post.content;

                final updated = await showModalBottomSheet<bool>(
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
                      promptMessage: "",
                      isEdit: true,
                      postToEdit: post,
                    ),
                  ),
                );

                controller.contentController.clear();
                controller.updateFormValidity();

                if (updated == true) {
                  ToastService.success('Post Updated Successfully');
                }
              } else if (value == 'delete') {
                final confirm = await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: const Text('Delete'),
                    content: const Text(
                      'Are you sure you want to delete this post?',
                    ),
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
                          "Confirm",
                          style: TextStyle(fontFamily: 'K2D', fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await controller.deletePost(post.id);
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: BColors.primary),
                    const SizedBox(width: 8),
                    const Text("Edit"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: BColors.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text("Delete"),
                  ],
                ),
              ),
            ],
          )
        else
          // Someone Else's Post: Report Icon 
          IconButton(
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
                          key: ValueKey('reporting_${post.id}'),
                          color: BColors.error,
                          size: BSizes.iconMd,
                        )
                      : Icon(
                          Icons.flag_outlined,
                          key: ValueKey('unreported_${post.id}'),
                          color: BColors.primary,
                          size: BSizes.iconMd,
                        ),
                );
              },
            ),
            tooltip: 'Report Post',
            onPressed: () async {
              final confirm = await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: const Text('Report'),
                  content: const Text(
                    'Are you sure you want to report this Post?',
                  ),
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
                        "Confirm",
                        style: TextStyle(fontFamily: 'K2D', fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                reportNotifier.value = true;
                await controller.reportPost(post.id);
                Future.delayed(const Duration(milliseconds: 600), () {
                  reportNotifier.value = false;
                });
              }
            },
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
          Row(
            children: [
              Text(
                'Posted ${post.createdAt.toDate().toLocal().toString().split(' ')[0]}',
                style: BTextTheme.lightTextTheme.labelMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (post.isEdited)
                Text(
                  "    (Edited)",
                  style: BTextTheme.lightTextTheme.labelMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),

          SizedBox(height: BSizes.xs),
          Divider(indent: 0.5, endIndent: 0.5, color: BColors.grey),
        ],
      ),
    );
  }

  Widget _postActionButtons(BuildContext context, Post post) {
    return Row(
      children: [
        SizedBox(width: BSizes.md),
        _LikeButton(post: post, controller: controller),
        SizedBox(width: BSizes.xs),
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
              duration: const Duration(milliseconds: 245),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: isShowingCheck
                  ? Icon(
                      Icons.check_rounded,
                      key: ValueKey('check_${post.id}'),
                      color: const Color.fromARGB(255, 241, 205, 99),
                      size: BSizes.iconMd,
                    )
                  : Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      key: ValueKey('bookmark_${post.id}'),
                      color: isSaved
                          ? const Color.fromARGB(255, 241, 205, 99)
                          : BColors.primary,
                      size: BSizes.iconMd,
                    ),
            ),
          );
        }),
        SizedBox(width: BSizes.sm),
        IconButton(
          icon: const Icon(Icons.comment_outlined, size: BSizes.iconMd - 1.5, color: BColors.primary,),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CommentsPage(postId: post.id, postUserName: post.userName),
              ),
            );
          },

          color: BColors.darkGrey,
          tooltip: 'Comment',
        ),
      ],
    );
  }
}

class _LikeButton extends StatefulWidget {
  final Post post;
  final PostControllerX controller;
  const _LikeButton({required this.post, required this.controller});
  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _animController.reset();
    _animController.forward().then((_) => _animController.reverse());
    widget.controller.toggleLike(widget.post.id);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLiked = widget.controller.isPostLiked(widget.post.id);
      final likeCount = widget.controller.getLikeCount(widget.post.id);
      return GestureDetector(
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_animController.value * 0.15),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: BSizes.iconMd,
                    color: isLiked ? Colors.red : BColors.primary,
                  ),
                  SizedBox(
                    width: 24,
                    child: likeCount > 0
                        ? Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              '$likeCount',
                              style: BTextTheme.lightTextTheme.labelMedium
                                  ?.copyWith(color: BColors.primary),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}
