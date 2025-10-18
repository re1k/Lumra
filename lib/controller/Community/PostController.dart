import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lumra_project/model/community/communityModel.dart';
import 'package:lumra_project/utils/customWidgets/toastservice.dart';

class PostControllerX extends GetxController {
  final FirebaseFirestore db;
  final contentController = TextEditingController();

  PostControllerX(this.db);

  // Get current user ID dynamically from Firebase Auth
  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  var contentError = RxnString();

  var isFormValid = false.obs;
  var isLoading = false.obs;

  var posts = <Post>[].obs;
  var savedPosts = <Post>[].obs;
  var userPosts = <Post>[].obs;

  late String communityCollection;
  var savedPostIds = <String>[].obs;
  var showingCheckIds = <String>[].obs;

  var isInit = false;
  var isInitialized = false.obs;

  StreamSubscription<QuerySnapshot>? _postsSubscription;
  StreamSubscription<QuerySnapshot>? _savedPostsSubscription;
  StreamSubscription<QuerySnapshot>? _userPostsSubscription;

  @override
  void onInit() {
    super.onInit();
    _init();
    contentController.addListener(updateFormValidity);
  }

  @override
  void onClose() {
    _postsSubscription?.cancel();
    _savedPostsSubscription?.cancel();
    contentController.dispose();
    super.onClose();
  }

  /// Initializes community collection and sets up real-time listeners
  Future<void> _init() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .get();

    String role = 'adhd';

    print("-------the inital community role is $role");
    if (userDoc.exists) {
      final data = userDoc.data();
      if (data != null && data['role'] != null) {
        role = data['role'].toString().toLowerCase();
      }
    }
    print("-------the community role is $role");

    communityCollection = role == 'caregiver'
        ? 'CareGiverCommunityPosts'
        : 'ADHDCommunityPosts';

    // Real-time updates
    print('Setting up real-time listener for collection: $communityCollection');
    _postsSubscription = db
        .collection(communityCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          print('Real-time listener received ${snapshot.docs.length} posts');
          posts.value = snapshot.docs.map(Post.fromFirestore).toList();
        }, onError: (e) => print('Error fetching posts: $e'));

    listenToSavedPosts();
    listenToUserPosts();
    isInitialized.value = true;
  }

  /// Updates community collection based on current user's role
  Future<void> _updateCommunityCollection() async {
    if (currentUid == null) {
      // If no user is logged in, default to ADHD community
      communityCollection = 'ADHDCommunityPosts';
      return;
    }

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
  }

  /// Manual fetching method (can be used on initState or pull-to-refresh)
  Future<void> fetchPosts() async {
    try {
      isLoading.value = true;
      // Update community collection to ensure we're using the current user's role
      await _updateCommunityCollection();

      final snapshot = await db
          .collection(communityCollection)
          .orderBy('createdAt', descending: true)
          .get();

      posts.value = snapshot.docs.map(Post.fromFirestore).toList();

      // Refresh saved posts listener to ensure it's listening to current user
      refreshSavedPostsListener();
    } catch (e) {
      ToastService.error("Failed to fetch posts. Try again!");
      debugPrint('fetchPosts error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh saved posts listener for current user
  void refreshSavedPostsListener() {
    listenToSavedPosts();
  }

 /// Refresh user posts listener for current user
void refreshUserPostsListener() {
  listenToUserPosts();
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

    if (currentUid == null) {
      ToastService.error("You must be logged in to create a post");
      return;
    }

    try {
      isLoading.value = true;
      // Update community collection to ensure we're using the current user's role
      await _updateCommunityCollection();

      // Use the controller's currentUid to ensure consistency
      final userDoc = await db.collection("users").doc(currentUid).get();

      final firstName = userDoc['firstName'] ?? '';
      final lastName = userDoc['lastName'] ?? '';
      final displayName = (firstName + ' ' + lastName).trim();

      final post = Post(
        userId: currentUid!,
        userName: displayName,
        content: text,
        createdAt: Timestamp.now(),
        id: '',
      );

      print('Adding post to collection: $communityCollection');
      final docRef = await db
          .collection(communityCollection)
          .add(post.toFirestore());
      await docRef.update({'id': docRef.id});
      print('Post added successfully with ID: ${docRef.id}');
      contentController.clear();

      // Manually refresh posts to ensure UI updates immediately
      print('Manually refreshing posts...');
      await fetchPosts();
    } catch (e) {
      ToastService.error("Could not add post. Try again!");
    } finally {
      isLoading.value = false;
    }
  }


void listenToUserPosts() {
  // Clear existing posts to prevent duplicates
  userPosts.clear();

  // Cancel any existing subscription
  _userPostsSubscription?.cancel();

  if (currentUid == null) {
    print('No user logged in, skipping user posts listener');
    return;
  }

  print('Setting up user posts listener for user: $currentUid');

  _userPostsSubscription = db
      .collection(communityCollection)
      .where('userId', isEqualTo: currentUid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .listen(
        (snapshot) {
          print('User posts listener received ${snapshot.docs.length} posts');
          userPosts.value = snapshot.docs.map(Post.fromFirestore).toList();
        },
        onError: (e) {
          print('Error in user posts listener: $e');
        },
      );
}

  void listenToSavedPosts() {
    // Clear existing reactive lists
    savedPosts.clear();
    savedPostIds.clear();

    // Cancel existing subscription
    _savedPostsSubscription?.cancel();

    if (currentUid == null) {
      return; // No user logged in, don't set up listeners
    }

    print('Setting up saved posts listener for user: $currentUid');

    // Listen to the current user's savedPosts subcollection in real-time
    _savedPostsSubscription = db
        .collection('users')
        .doc(currentUid)
        .collection('savedPosts')
        .snapshots()
        .listen(
          (snapshot) async {
            // Extract postIds from the savedPosts documents
            final postIds = snapshot.docs
                .map((doc) => doc['postId'] as String)
                .toList();

            print(
              'Saved posts listener received ${postIds.length} saved post IDs for user: $currentUid',
            );

            // Update reactive list of saved post IDs
            savedPostIds.value = postIds;

            // If the user has no saved posts, clear savedPosts and return
            if (postIds.isEmpty) {
              savedPosts.clear();
              return;
            }

            // Update community collection to ensure we're using the current user's role
            await _updateCommunityCollection();

            // Fetch actual post documents in batches of 10 (Firestore whereIn limit)
            List<Post> fetchedPosts = [];
            const batchSize = 10;
            for (var i = 0; i < postIds.length; i += batchSize) {
              final batchIds = postIds.sublist(
                i,
                i + batchSize > postIds.length ? postIds.length : i + batchSize,
              );

              final postsSnap = await db
                  .collection(communityCollection)
                  .where(FieldPath.documentId, whereIn: batchIds)
                  .get();

              fetchedPosts.addAll(postsSnap.docs.map(Post.fromFirestore));
            }

            // Update reactive list of saved posts (UI will automatically update via Obx)
            savedPosts.value = fetchedPosts;

            print(
              'Fetched ${fetchedPosts.length} saved posts for user: $currentUid',
            );
          },
          onError: (e) {
            print('Error in saved posts listener: $e');
          },
        );
  }

  bool isPostSaved(String postId) => savedPostIds.contains(postId);
  bool isShowingCheck(String postId) => showingCheckIds.contains(postId);

  Future<void> savePost(Post post) async {
    if (currentUid == null) {
      ToastService.error("You must be logged in to save posts");
      return;
    }

    try {
      await db
          .collection('users')
          .doc(currentUid)
          .collection('savedPosts')
          .doc(post.id)
          .set({'postId': post.id, 'savedAt': FieldValue.serverTimestamp()});

      // Update reactive lists immediately for instant UI feedback
      savedPostIds.add(post.id);
      savedPosts.add(post);
    } catch (e) {
      debugPrint('savePost error: $e');
    }
  }

  Future<void> unsavePost(String postId) async {
    if (currentUid == null) {
      ToastService.error("You must be logged in to unsave posts");
      return;
    }

    try {
      await db
          .collection('users')
          .doc(currentUid)
          .collection('savedPosts')
          .doc(postId)
          .delete();

      // Update reactive lists immediately for instant UI feedback
      savedPostIds.remove(postId);
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
