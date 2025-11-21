import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/Admin/admin_posts_controller.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/theme/custom_themes/text_theme.dart';
import 'package:lumra_project/model/community/communityModel.dart';
import 'package:lumra_project/view/Admin/admin_comments_page.dart';
import 'package:lumra_project/view/Admin/dialog_helper.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';
import 'package:lumra_project/view/welcomePage.dart';
import 'package:lumra_project/utils/customWidgets/toastservice.dart';

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
        icon: const Icon(Icons.logout, color: BColors.primary),
        onPressed: () {
          _showAdminLogoutDialog(context, authController);
        },
      ),
    );
  }

  void _showAdminLogoutDialog(
    BuildContext context,
    AuthController authController,
  ) {
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
  // ---------------- REPORTED VIEW ( post + comment ) ----------------
  Widget _reportedPostsView() {
    return Obx(() {
      if (adminController.allReportedItems.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Text(
              "Nothing reported yet.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        );
      }

      return ListView.separated(
        itemCount: adminController.allReportedItems.length,
        separatorBuilder: (_, __) => SizedBox(height: BSizes.SpaceBtwItems),
        itemBuilder: (context, index) {
          final item = adminController.allReportedItems[index];

          final type = item["type"];
          final userName = item["userName"];
          final content = item["content"];
          final date = item["date"].toDate().toString().split(" ")[0];

          final icon = type == "post"
              ? Icon(Icons.article, color: BColors.primary)
              : Icon(Icons.chat_bubble_outline, color: Colors.orange);

          return _reportedCard(item);
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
          _postContent(content),
          const SizedBox(height: BSizes.sm),
          _actions(postId, userName, collection, userId, date),
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

  Widget _postContent(String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BSizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(content), const SizedBox(height: 6)],
      ),
    );
  }

  Widget _actions(
    String postId,
    String userName,
    String collection,
    String userId,
    String date,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          "Posted $date",
          style: BTextTheme.lightTextTheme.labelMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: BColors.darkGrey,
          ),
        ),
        const Spacer(),

        IconButton(
          icon: const Icon(Icons.comment_outlined, size: BSizes.iconMd - 1),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminCommentsPage(
                  postId: postId,
                  postUserName: userName,
                  collectionName: collection,
                ),
              ),
            );
          },
          color: BColors.darkGrey,
          tooltip: 'Comments',
        ),

        const SizedBox(width: 10),

        IconButton(
          icon: Icon(Icons.delete_outline, color: BColors.error),
          tooltip: 'Delete Post',
          onPressed: () async {
            final confirm = await showConfirmDialog(
              context: context,
              title: "Delete Post?",
              message: "This action is permanent.",
            );

            if (confirm == true) {
              await adminController.deletePost(postId, collection, userId);

              ToastService.success("Post has been deleted successfully!");
            }
          },
        ),
      ],
    );
  }

  Widget _reportedCard(Map<String, dynamic> item) {
    final type = item["type"]; // post OR comment
    final isPost = type == "post";

    final userName = item["userName"];
    final content = item["content"];
    final date = item["date"].toDate().toString().split(" ")[0];

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
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
                  const SizedBox(width: 8),
                  Text(userName, style: BTextTheme.lightTextTheme.labelLarge),
                ],
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPost ? BColors.primary : BColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPost ? "POST" : "COMMENT",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: BSizes.sm),

          _postContent(content),

          const SizedBox(height: 6),

          const SizedBox(height: BSizes.sm),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "Posted $date",
                style: BTextTheme.lightTextTheme.labelMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: BColors.darkGrey,
                ),
              ),
              const Spacer(),

              // IGNORE
              TextButton(
                onPressed: () async {
                  final confirm = await showConfirmDialog(
                    context: context,
                    title: "Ignore Report?",
                    message: "Are you sure you want to ignore this report?",
                  );

                  if (confirm == true) {
                    if (item["type"] == "post") {
                      adminController.ignorePost(
                        item["postId"],
                        item["collection"],
                      );
                    } else {
                      adminController.ignoreComment(
                        postId: item["postId"],
                        collection: item["collection"],
                        commentDocId: item["docId"],
                      );
                    }

                    ToastService.info(
                      "Ignored",
                      "Report has been ignored successfully!",
                    );
                  }
                },
                child: const Text(
                  "Ignore",
                  style: TextStyle(
                    color: BColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // DELETE
              IconButton(
                icon: const Icon(Icons.delete_outline, color: BColors.error),
                onPressed: () async {
                  final confirm = await showConfirmDialog(
                    context: context,
                    title: "Delete Comment?",
                    message: "This action is permanent.",
                  );

                  if (confirm == true) {
                    if (isPost) {
                      await adminController.deletePost(
                        item["postId"],
                        item["collection"],
                        item["userId"],
                      );
                    } else {
                      await adminController.deleteReportedComment(
                        postId: item["postId"],
                        collection: item["collection"],
                        commentDocId: item["docId"],
                      );
                    }
                    ToastService.success("Removed successfully!");
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
