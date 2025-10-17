import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/model/community/communityModel.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';
import 'package:lumra_project/utils/customWidgets/toastservice.dart';
class PostControllerX extends GetxController {
  final FirebaseFirestore db;
  final String currentUid;
  final contentController = TextEditingController();

  PostControllerX(this.db, this.currentUid);

  var contentError = RxnString();
  var isFormValid = false.obs;
  var isLoading = false.obs;
  var posts = <Post>[].obs;
  var savedPosts = <Post>[].obs;
  late String communityCollection;
  var savedPostIds = <String>[].obs;
  var showingCheckIds = <String>[].obs;
  var isInit = false;
  var isInitialized = false.obs;

  @override
  void onInit() {
    super.onInit();
    _init();
    contentController.addListener(updateFormValidity);
  }

  /// 🔹 Initializes community collection and sets up real-time listeners
  Future<void> _init() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .get();

    String role = 'adhd';
    if (userDoc.exists) {
      final data = userDoc.data();
      if (data != null && data['role'] != null) {
        role = data['role'].toString().toLowerCase();
      }
    }

    communityCollection = role == 'caregiver'
        ? 'CareGiverCommunityPosts'
        : 'ADHDCommunityPosts';

    // Real-time updates
    db
        .collection(communityCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        posts.value = snapshot.docs.map(Post.fromFirestore).toList();
      },
      onError: (e) => print('Error fetching posts: $e'),
    );

    listenToSavedPosts();
    isInitialized.value = true;
  }

  /// Manual fetching method (can be used on initState or pull-to-refresh)
  Future<void> fetchPosts() async {
    try {
      isLoading.value = true;
      final snapshot = await db
          .collection(communityCollection)
          .orderBy('createdAt', descending: true)
          .get();

      posts.value = snapshot.docs.map(Post.fromFirestore).toList();
    } catch (e) {
      ToastService.error("Failed to fetch posts. Try again!");
      debugPrint('fetchPosts error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void updateFormValidity() {
    final text = contentController.text.trim();
    if (text.isEmpty) {
      contentError.value = "Post cannot be empty";
      isFormValid.value = false;
    } else {
      contentError.value = null;
      isFormValid.value = true;
    }
  }

  Future<void> addPost() async {
    if (!isFormValid.value) return;

    final text = contentController.text.trim();
    if (text.isEmpty) {
      ToastService.error("Post cannot be empty");
      return;
    }

    try {
      isLoading.value = true;
      final authController = Get.find<AuthController>();
      final authUser = authController.currentUser!.uid;
      final userDoc = await db.collection("users").doc(authUser).get();

      final firstName = userDoc['firstName'] ?? '';
      final lastName = userDoc['lastName'] ?? '';
      final displayName = (firstName + ' ' + lastName).trim();

      final post = Post(
        userId: authUser,
        userName: displayName,
        content: text,
        createdAt: Timestamp.now(),
        id: '',
      );

      final docRef =
          await db.collection(communityCollection).add(post.toFirestore());
      await docRef.update({'id': docRef.id});
      contentController.clear();
    } catch (e) {
      ToastService.error("Could not add post. Try again!");
    } finally {
      isLoading.value = false;
    }
  }

 void listenToSavedPosts() {
  // Clear existing reactive lists
  savedPosts.clear();
  savedPostIds.clear();

  // Listen to the current user's savedPosts subcollection in real-time
  db
      .collection('users')
      .doc(currentUid)
      .collection('savedPosts')
      .snapshots()
      .listen((snapshot) async {
    // Extract postIds from the savedPosts documents
    final postIds = snapshot.docs
        .map((doc) => doc['postId'] as String)
        .toList();

    // Update reactive list of saved post IDs
    savedPostIds.value = postIds;

    // If the user has no saved posts, clear savedPosts and return
    if (postIds.isEmpty) {
      savedPosts.clear();
      return;
    }

    // Fetch actual post documents in batches of 10 (Firestore whereIn limit)
    List<Post> fetchedPosts = [];
    const batchSize = 10;
    for (var i = 0; i < postIds.length; i += batchSize) {
      final batchIds = postIds.sublist(
          i, i + batchSize > postIds.length ? postIds.length : i + batchSize);

      final postsSnap = await db
          .collection(communityCollection)
          .where(FieldPath.documentId, whereIn: batchIds)
          .get();

      fetchedPosts.addAll(postsSnap.docs.map(Post.fromFirestore));
    }

    // Update reactive list of saved posts (UI will automatically update via Obx)
    savedPosts.value = fetchedPosts;

    // 🔹 Optional debug print
    debugPrint('Fetched saved posts for current user: $postIds');
  });
}

  bool isPostSaved(String postId) => savedPosts.any((post) => post.id == postId);
  bool isShowingCheck(String postId) => showingCheckIds.contains(postId);

  Future<void> savePost(Post post) async {
    try {
      await db
          .collection('users')
          .doc(currentUid)
          .collection('savedPosts')
          .doc(post.id)
          .set({'postId': post.id, 'savedAt': FieldValue.serverTimestamp()});

      savedPostIds.add(post.id);
    } catch (e) {
      debugPrint('savePost error: $e');
    }
  }

  Future<void> unsavePost(String postId) async {
    try {
      await db
          .collection('users')
          .doc(currentUid)
          .collection('savedPosts')
          .doc(postId)
          .delete();

      savedPosts.removeWhere((p) => p.id == postId);
    } catch (e) {
      debugPrint('unsavePost error: $e');
    }
  }

  void showBookmarkCheck(String postId) {
    showingCheckIds.add(postId);
    Future.delayed(const Duration(milliseconds: 400), () {
      showingCheckIds.remove(postId);
    });
  }
}



