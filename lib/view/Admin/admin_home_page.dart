import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/Admin/admin_posts_controller.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/theme/custom_themes/text_theme.dart';
import 'package:lumra_project/model/community/communityModel.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';
import 'package:lumra_project/view/welcomePage.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final adminController = Get.put(AdminPostsController());
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BColors.lightGrey,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context),
              const SizedBox(height: BSizes.lg),
              _tabs(),
              const SizedBox(height: BSizes.lg),

              Expanded(
                child: selectedTab == 0
                    ? _reportedPostsView()
                    : _allPostsView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------  
  Widget _header(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hello Layan",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: BColors.darkGrey,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Admin Panel",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: BColors.black,
                  fontSize: 28,
                ),
              ),
            ],
          ),
        ),
        _logoutButton(context),
      ],
    );
  }

  Widget _logoutButton(BuildContext context) {
    final authController = Get.find<AuthController>();
    return Container(
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
        tooltip: 'Logout',
        icon: const Icon(
          Icons.logout,
          color: BColors.primary,
        ),
        onPressed: () {
          _showAdminLogoutDialog(context, authController);
        },
      ),
    );
  }

  void _showAdminLogoutDialog(BuildContext context, AuthController authController) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 24,
          ),
          title: const Text(
            "Confirm Sign out",
            style: TextStyle(fontFamily: 'K2D', fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to sign out?",
            style: TextStyle(
              fontFamily: 'K2D',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(fontFamily: 'K2D', color: Colors.black87),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: BColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                minimumSize: const Size(90, 40),
              ),
              onPressed: () async {
                await authController.logout();
                Navigator.pop(context);
                Get.offAll(() => const Welcomepage());
              },
              child: const Text(
                "Confirm",
                style: TextStyle(
                  fontFamily: 'K2D',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------- CONNECTED TABS ----------------
  Widget _tabs() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
        border: Border.all(color: BColors.secondry),
      ),
      child: Row(
        children: [
          _tab(
            "Reported Posts",
            0,
            BorderRadius.only(
              topLeft: Radius.circular(BSizes.cardRadiusMd),
              bottomLeft: Radius.circular(BSizes.cardRadiusMd),
            ),
          ),
          _tab(
            "All Posts",
            1,
            BorderRadius.only(
              topRight: Radius.circular(BSizes.cardRadiusMd),
              bottomRight: Radius.circular(BSizes.cardRadiusMd),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String title, int index, BorderRadius radius) {
    final active = (selectedTab == index);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? BColors.primary : BColors.white,
            borderRadius: radius,
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: active ? BColors.white : BColors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- REPORTED POSTS VIEW ----------------
  Widget _reportedPostsView() {
    return Obx(() {
      if (adminController.reportedPosts.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Text(
              "No reported posts.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }

      return ListView.separated(
        itemCount: adminController.reportedPosts.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: BSizes.SpaceBtwItems),
        itemBuilder: (context, index) {
          final item = adminController.reportedPosts[index];
          final post = item["post"] as Post;

          return _postCard(
            userName: post.userName,
            content: post.content,
            date: post.createdAt.toDate().toString().split(' ')[0],
            showIgnore: true,
            postId: post.id,
            collection: item["collection"],
            userId: post.userId,
          );
        },
      );
    });
  }

  // ---------------- ALL POSTS VIEW ----------------
  Widget _allPostsView() {
    return Obx(() {
      return ListView.separated(
        itemCount: adminController.allPosts.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: BSizes.SpaceBtwItems),
        itemBuilder: (context, index) {
          final item = adminController.allPosts[index];
          final post = item["post"] as Post;

          return _postCard(
            userName: post.userName,
            content: post.content,
            date: post.createdAt.toDate().toString().split(' ')[0],
            showIgnore: false,
            postId: post.id,
            collection: item["collection"],
            userId: post.userId,
          );
        },
      );
    });
  }

  // ---------------- POST CARD ----------------
  Widget _postCard({
    required String userName,
    required String content,
    required String date,
    required bool showIgnore,
    required String postId,
    required String collection,
    required String userId,
  }) {
    return Container(
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
          _postHeader(userName),
          const SizedBox(height: BSizes.sm),
          _postContent(content, date),
          const SizedBox(height: BSizes.sm),
          _actions(showIgnore, postId, collection, userId),
        ],
      ),
    );
  }

  Widget _postHeader(String userName) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: BColors.secondry),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/AvatarSimple.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: BSizes.sm),
        Text(userName, style: BTextTheme.lightTextTheme.labelLarge),
      ],
    );
  }

  Widget _postContent(String content, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BSizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(content),
          const SizedBox(height: 6),
          Text(
            "Posted $date",
            style: BTextTheme.lightTextTheme.labelMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  _actions(bool showIgnore, String postId, String collection, String userId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // IGNORE
        if (showIgnore)
          GestureDetector(
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  insetPadding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 24,
                  ),
                  title: const Text(
                    'Ignore report?',
                    style: TextStyle(
                      fontFamily: 'K2D',
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  content: const Text(
                    'This post will return to the community feed.',
                    style: TextStyle(
                      fontFamily: 'K2D',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'K2D',
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        minimumSize: const Size(90, 40),
                      ),

                      onPressed: () => Navigator.of(ctx).pop(true),

                      child: const Text(
                        "Ignore",
                        style: TextStyle(
                          fontFamily: 'K2D',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (ok == true) {
                await adminController.ignorePost(postId, collection);
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                "Ignore",
                style: TextStyle(
                  color: BColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        SizedBox(width: 12),

        // DELETE
        GestureDetector(
          onTap: () async {
            final ok = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 24,
                ),
                title: const Text(
                  'Delete post?',
                  style: TextStyle(
                    fontFamily: 'K2D',
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                content: const Text(
                  'This action is permanent and cannot be undone.',
                  style: TextStyle(
                    fontFamily: 'K2D',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'K2D',
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      minimumSize: const Size(90, 40),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text(
                      "Delete",
                      style: TextStyle(
                        fontFamily: 'K2D',
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );

            if (ok == true) {
              await adminController.deletePost(postId, collection, userId);
            }
          },
          child: const Icon(Icons.delete, color: BColors.error),
        ),
      ],
    );
  }
}
