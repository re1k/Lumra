import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:lumra_project/model/community/communityModel.dart';

class AdminPostsController extends GetxController {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  var allPosts = <Map<String, dynamic>>[].obs; // {post, collection, raw}
  var reportedPosts = <Map<String, dynamic>>[].obs;
  var reportedComments = <Map<String, dynamic>>[].obs;
  var allReportedItems = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;

  StreamSubscription? _caregiverSub;
  StreamSubscription? _adhdSub;

  @override
  void onInit() {
    super.onInit();
    fetchAllPostsRealtime();
    listenReportedPostsRealtime();
    listenReportedCommentsRealtime();
  }

  @override
  void onClose() {
    _caregiverSub?.cancel();
    _adhdSub?.cancel();
    super.onClose();
  }

  // -------------------------------------------------------
  //  Real-time listeners from BOTH collections
  // -------------------------------------------------------
  void fetchAllPostsRealtime() {
    isLoading.value = true;

    _caregiverSub = db.collection("CareGiverCommunityPosts").snapshots().listen(
      (snapshot) {
        _process(snapshot.docs, "CareGiverCommunityPosts");
      },
    );

    _adhdSub = db.collection("ADHDCommunityPosts").snapshots().listen((
      snapshot,
    ) {
      _process(snapshot.docs, "ADHDCommunityPosts");
      isLoading.value = false;
    });
  }

  ///  Fetch all reported comments from all posts
  Future<void> fetchReportedComments() async {
    reportedComments.clear();

    final postsSnapshot = await db.collection("CareGiverCommunityPosts").get();
    final postsSnapshot2 = await db.collection("ADHDCommunityPosts").get();

    for (var postDoc in [...postsSnapshot.docs, ...postsSnapshot2.docs]) {
      final postId = postDoc.id;
      final collection = postDoc.reference.parent.id;

      final commentsSnap = await db
          .collection(collection)
          .doc(postId)
          .collection('comments')
          .where('isReported', isEqualTo: true)
          .get();

      for (var c in commentsSnap.docs) {
        reportedComments.add({
          "type": "comment",
          "postId": postId,
          "collection": collection,
          "data": c.data(),
          "docId": c.id,
        });
      }
    }

    mergeReportedItems();
  }

  ///  Merge reported posts + reported comments
  void mergeReportedItems() {
    final Map<String, Map<String, dynamic>> uniqueItems = {};

    // -------- POSTS --------
    for (var p in reportedPosts) {
      final post = p["post"] as Post;
      final collection = p["collection"] as String;

      final key = "post_${post.id}_$collection";

      uniqueItems[key] = {
        "type": "post",
        "userName": post.userName,
        "content": post.content,
        "date": post.createdAt,
        "postId": post.id,
        "collection": collection,
        "userId": post.userId,
      };
    }

    // -------- COMMENTS --------
    for (var c in reportedComments) {
      final data = c["data"] as Map<String, dynamic>;
      final postId = c["postId"] as String;
      final docId = c["docId"] as String;
      final collection = c["collection"] as String;

      final key = "comment_${postId}_${docId}_$collection";

      uniqueItems[key] = {
        "type": "comment",
        "userName": data["userName"],
        "content": data["content"],
        "date": data["createdAt"],
        "postId": postId,
        "docId": docId,
        "collection": collection,
      };
    }

    allReportedItems.assignAll(uniqueItems.values.toList());
  }

  void _process(List<QueryDocumentSnapshot> docs, String fromCollection) {
    List<Map<String, dynamic>> incoming = docs.map((doc) {
      return {
        "post": Post.fromFirestore(doc),
        "collection": fromCollection,
        "raw": doc.data(),
      };
    }).toList();

    allPosts.removeWhere((item) => item["collection"] == fromCollection);

    allPosts.addAll(incoming);

    allPosts.sort((a, b) {
      final p1 = a["post"] as Post;
      final p2 = b["post"] as Post;
      return p2.createdAt.compareTo(p1.createdAt);
    });

    reportedPosts.value = allPosts.where((item) {
      final raw = item["raw"] as Map<String, dynamic>;
      return raw["isReported"] == true;
    }).toList();
    mergeReportedItems();
  }

  // -------------------------------------------------------
  //  Ignore → make isReported = false
  // -------------------------------------------------------
  Future<void> ignorePost(String postId, String collection) async {
    await db.collection(collection).doc(postId).update({"isReported": false});
  }

  Future<void> deleteSubcollection(
    String collection,
    String postId,
    String sub,
  ) async {
    final ref = db.collection(collection).doc(postId).collection(sub);

    final snapshots = await ref.get();

    for (var doc in snapshots.docs) {
      await ref.doc(doc.id).delete();
    }
  }

  // -------------------------------------------------------
  //  Delete permanently  +  update user deletedPostsCount
  // -------------------------------------------------------
  Future<void> deletePost(
    String postId,
    String collection,
    String userId,
  ) async {
    try {
      await deleteSubcollection(collection, postId, "comments");
      await deleteSubcollection(collection, postId, "likes");

      await db.collection(collection).doc(postId).delete();
      await incrementDeletedCountForUser(userId);
    } catch (e) {
      print('Error in deletePost: $e');
    }
  }

  Future<void> deleteReportedComment({
    required String postId,
    required String collection,
    required String commentDocId,
  }) async {
    try {
      final docSnap = await db
          .collection(collection)
          .doc(postId)
          .collection('comments')
          .doc(commentDocId)
          .get();

      final data = docSnap.data() as Map<String, dynamic>?;

      await db
          .collection(collection)
          .doc(postId)
          .collection('comments')
          .doc(commentDocId)
          .delete();

      if (data != null && data["userId"] != null) {
        await incrementDeletedCountForUser(data["userId"]);
      }

      reportedComments.removeWhere((c) => c["docId"] == commentDocId);
      mergeReportedItems();
    } catch (e) {
      print('Error deleting comment: $e');
    }
  }

  Future<void> fetchReportedPosts() async {
    reportedPosts.clear();

    final snap1 = await db
        .collection("CareGiverCommunityPosts")
        .where('isReported', isEqualTo: true)
        .get();

    final snap2 = await db
        .collection("ADHDCommunityPosts")
        .where('isReported', isEqualTo: true)
        .get();

    for (var doc in [...snap1.docs, ...snap2.docs]) {
      reportedPosts.add({
        "type": "post",
        "postId": doc.id,
        "post": Post.fromFirestore(doc),
        "collection": doc.reference.parent.id,
      });
    }
    mergeReportedItems();
  }

  void listenReportedPostsRealtime() {
    reportedPosts.clear();

    // Caregiver posts
    db
        .collection("CareGiverCommunityPosts")
        .where('isReported', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
          for (var doc in snapshot.docs) {
            reportedPosts.removeWhere(
              (item) =>
                  item["postId"] == doc.id &&
                  item["collection"] == doc.reference.parent.id,
            );

            reportedPosts.add({
              "type": "post",
              "postId": doc.id,
              "post": Post.fromFirestore(doc),
              "collection": doc.reference.parent.id,
            });
          }
          mergeReportedItems();
        });

    // ADHD posts
    db
        .collection("ADHDCommunityPosts")
        .where('isReported', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
          for (var doc in snapshot.docs) {
            reportedPosts.removeWhere(
              (item) =>
                  item["postId"] == doc.id &&
                  item["collection"] == doc.reference.parent.id,
            );

            reportedPosts.removeWhere(
              (item) =>
                  item["postId"] == doc.id &&
                  item["collection"] == doc.reference.parent.id,
            );

            reportedPosts.add({
              "type": "post",
              "postId": doc.id,
              "post": Post.fromFirestore(doc),
              "collection": doc.reference.parent.id,
            });
          }
          mergeReportedItems();
        });
  }

  void listenReportedCommentsRealtime() async {
    final caregivers = await db.collection("CareGiverCommunityPosts").get();
    final adhd = await db.collection("ADHDCommunityPosts").get();

    for (var postDoc in [...caregivers.docs, ...adhd.docs]) {
      db
          .collection(postDoc.reference.parent.id)
          .doc(postDoc.id)
          .collection('comments')
          .where('isReported', isEqualTo: true)
          .snapshots()
          .listen((snap) {
            reportedComments.removeWhere((c) => c["postId"] == postDoc.id);
            for (var c in snap.docs) {
              reportedComments.add({
                "type": "comment",
                "postId": postDoc.id,
                "collection": postDoc.reference.parent.id,
                "data": c.data(),
                "docId": c.id,
              });
            }
            mergeReportedItems();
          });
    }
  }

  Future<void> ignoreComment({
    required String postId,
    required String collection,
    required String commentDocId,
  }) async {
    await db
        .collection(collection)
        .doc(postId)
        .collection('comments')
        .doc(commentDocId)
        .update({"isReported": false});

    reportedComments.removeWhere((c) => c["docId"] == commentDocId);
    mergeReportedItems();
  }

  Future<void> incrementDeletedCountForUser(String userId) async {
    final userRef = db.collection('users').doc(userId);

    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final data = snapshot.data() as Map<String, dynamic>? ?? {};

      int currentCount = data['deletedPostsCount'] is int
          ? data['deletedPostsCount']
          : int.tryParse("${data['deletedPostsCount']}") ?? 0;

      final newCount = currentCount + 1;

      final updateData = <String, dynamic>{'deletedPostsCount': newCount};

      if (newCount >= 6 && data['reachedSixAt'] == null) {
        updateData['reachedSixAt'] = FieldValue.serverTimestamp();
      }

      transaction.set(userRef, updateData, SetOptions(merge: true));
    });

    print(' deletedPostsCount updated for $userId');
  }
}
