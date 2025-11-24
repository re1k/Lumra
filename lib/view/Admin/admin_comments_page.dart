import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/theme/custom_themes/text_theme.dart';
import 'package:lumra_project/theme/custom_themes/appbar_theme.dart';
import 'package:lumra_project/view/Admin/dialog_helper.dart';
import 'package:lumra_project/utils/customWidgets/toastservice.dart';
import 'package:lumra_project/controller/Admin/admin_posts_controller.dart';
import 'package:get/get.dart';

class AdminCommentsPage extends StatefulWidget {
  final String postId;
  final String postUserName;
  final String collectionName;

  const AdminCommentsPage({
    super.key,
    required this.postId,
    required this.postUserName,
    required this.collectionName,
  });

  @override
  _AdminCommentsPageState createState() => _AdminCommentsPageState();
}

class _AdminCommentsPageState extends State<AdminCommentsPage> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _commentsStream;

  @override
  void initState() {
    super.initState();
    _commentsStream = db
        .collection(widget.collectionName)
        .doc(widget.postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BColors.lightGrey,

      body: Column(
        children: [
          BAppBarTheme.createHeader(
            context: context,
            title: "Comments",
            subtitle: "for ${widget.postUserName}’s post",
            showBackButton: true,
            onBackPressed: () => Navigator.pop(context),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _commentsStream,
              builder: (_, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data!.docs;

                if (comments.isEmpty) {
                  return const Center(
                    child: Text(
                      'No Comments Yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (_, i) {
                    final data = comments[i].data() as Map<String, dynamic>;
                    return _commentCard(comments[i], data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  final adminController = Get.find<AdminPostsController>();

  Widget _commentCard(DocumentSnapshot doc, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BColors.secondry),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Header: Avatar + Username + Delete
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
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
                  const SizedBox(width: 8),
                  Text(
                    data['userName'] ?? 'Unknown',
                    style: BTextTheme.lightTextTheme.labelLarge,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            data['content'] ?? '',
            style: BTextTheme.lightTextTheme.bodyMedium,
          ),

          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Commented ${data['createdAt']?.toDate().toString().split(" ")[0] ?? ''}',
                style: BTextTheme.lightTextTheme.labelMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: BColors.darkGrey,
                  fontSize: 12,
                ),
              ),

              IconButton(
                icon: const Icon(Icons.delete_outline, color: BColors.error),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () async {
                  final confirm = await showConfirmDialog(
                    context: context,
                    title: "Delete Comment?",
                    message: "This action is permanent.",
                  );

                  if (confirm == true) {
                    await _deleteComment(doc.id);

                    if (data['userId'] != null) {
                      await adminController.incrementDeletedCountForUser(
                        data['userId'],
                      );
                    }

                    ToastService.success("Comment removed successfully");
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  //  delete comment (Firestore)
  Future<void> _deleteComment(String commentId) async {
    final postRef = db.collection(widget.collectionName).doc(widget.postId);

    await postRef.collection('comments').doc(commentId).delete();
  }
}
