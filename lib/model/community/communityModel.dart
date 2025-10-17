import 'package:cloud_firestore/cloud_firestore.dart';


class Post {
  final String userId;
  final String userName;
  final String content;
  final Timestamp createdAt;
  String id;

  Post({
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
    required this.id,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      content: data['content'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      id: doc.id,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'content': content,
      'createdAt': createdAt,
    };
  }
}
