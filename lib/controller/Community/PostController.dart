import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lumra_project/model/community/comments.dart';
import 'package:lumra_project/model/community/communityModel.dart';
import 'package:lumra_project/utils/customWidgets/toastservice.dart';
import 'package:profanity_filter/profanity_filter.dart';

class PostControllerX extends GetxController {
  final FirebaseFirestore db;
  final contentController = TextEditingController();
  final _profanityFilter = ProfanityFilter();
  final List<String> _bannedWords = [];
  var _bannedWordsLoaded = false.obs;

  PostControllerX(this.db);

  // Get current user ID dynamically from Firebase Auth
  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  var contentError = RxnString();
  var hasRestrictedContent = false.obs;
  var hasInteracted = false.obs;

  var isFormValid = false.obs;
  var isLoading = false.obs;

  var posts = <Post>[].obs;
  var savedPosts = <Post>[].obs;
  var userPosts = <Post>[].obs;
  var Comments = <Comment>[].obs;

  late String communityCollection;
  var savedPostIds = <String>[].obs;
  var showingCheckIds = <String>[].obs;
  var likedPostIds = <String>[].obs;
  var likeCounts = <String, int>{}.obs;

  var isInit = false;
  var isInitialized = false.obs;

  var currentLength = 0.obs;

  StreamSubscription<QuerySnapshot>? _postsSubscription;
  StreamSubscription<QuerySnapshot>? _savedPostsSubscription;
  StreamSubscription<QuerySnapshot>? _userPostsSubscription;

  final Map<String, StreamSubscription<QuerySnapshot>> _commentsSubscriptions =
      {};
  final Map<String, RxList<Comment>> _commentsPerPost = {};

  // Each like is stored once at /{postId}/likes/{userId}
  final Map<String, StreamSubscription<QuerySnapshot>> _likesSubscriptions = {};
  final Set<String> _likeOpsInFlight = {};
  @override
  void onInit() {
    super.onInit();

    hasInteracted.value = false;
    contentError.value = null;
    hasRestrictedContent.value = false;
    _init();
    contentController.addListener(updateFormValidity);
  }

  @override
  void onClose() {
    _postsSubscription?.cancel();
    _savedPostsSubscription?.cancel();
    _userPostsSubscription?.cancel();
    _clearLikesSubscriptions();
    likedPostIds.clear();
    likeCounts.clear();
    savedPostIds.clear();
    savedPosts.clear();
    userPosts.clear();
    posts.clear();
    contentController.dispose();
    communityCollection = '';
    // Cancel all comments subscriptions
    for (final sub in _commentsSubscriptions.values) {
      sub.cancel();
    }
    _commentsSubscriptions.clear();
    super.onClose();
  }

  /// Initializes community collection and sets up real-time listeners
  Future<void> _init() async {
    await _loadBannedWords();

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
    //
    _postsSubscription?.cancel();
    //
    _postsSubscription = db
        .collection(communityCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          print('Real-time listener received ${snapshot.docs.length} posts');
          posts.value = snapshot.docs.map(Post.fromFirestore).toList();
          _setupLikesSubscriptions(snapshot.docs);
        }, onError: (e) => print('Error fetching posts: $e'));

    listenToSavedPosts();
    listenToUserPosts();
    isInitialized.value = true;
  }

  Future<void> _loadBannedWords() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/banned_words.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _bannedWords.clear();
      _bannedWords.addAll(List<String>.from(jsonData['bannedWords']));
      _bannedWordsLoaded.value = true;
    } catch (e) {
      debugPrint('Error loading banned words: $e');
      _bannedWordsLoaded.value = false;
    }
  }

  bool _containsBannedWords(String text) {
    if (!_bannedWordsLoaded.value || _bannedWords.isEmpty) {
      return false;
    }

    String normalizedText = text.toLowerCase();
    normalizedText = normalizedText.replaceAll(RegExp(r'\s+'), ' ');
    normalizedText = normalizedText.replaceAll("'", "'");
    normalizedText = normalizedText.replaceAll("'", "'");
    normalizedText = normalizedText.replaceAll("wanna", "want to");
    normalizedText = normalizedText.replaceAll("gonna", "going to");
    normalizedText = normalizedText.replaceAll("cant", "can't");
    normalizedText = normalizedText.replaceAll("cannot", "can't");
    normalizedText = normalizedText.replaceAll("-", " ");

    for (final bannedWord in _bannedWords) {
      String normalizedBanned = bannedWord.toLowerCase().trim();
      if (normalizedBanned.isEmpty) continue;
      normalizedBanned = normalizedBanned.replaceAll(RegExp(r'\s+'), ' ');
      normalizedBanned = normalizedBanned.replaceAll("'", "'");
      normalizedBanned = normalizedBanned.replaceAll("'", "'");
      normalizedBanned = normalizedBanned.replaceAll("-", " ");

      final escapedBanned = RegExp.escape(normalizedBanned);
      final wordBoundaryPattern = RegExp(
        r'\b' + escapedBanned + r'\b',
        caseSensitive: false,
      );

      if (wordBoundaryPattern.hasMatch(normalizedText)) {
        return true;
      }
    }

    return false;
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
      _setupLikesSubscriptions(snapshot.docs);
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

  void resetFormState() {
    hasInteracted.value = false;
    contentError.value = null;
    hasRestrictedContent.value = false;
    isFormValid.value = false;
    originalContent = null;
  }

  void updateFormValidity({bool markInteracted = true}) {
    var text = contentController.text;
    currentLength.value = text.length;

    // Regex: checks if the string contains only special characters or spaces
    final onlySpecialChars = RegExp(r'^[^a-zA-Z0-9]+$');

    if (text.isEmpty || isContentNotChanged() ) {
      hasInteracted.value = false;
      contentError.value = null;
      hasRestrictedContent.value = false;
      isFormValid.value = false;
    } else {
      if (markInteracted) {
        hasInteracted.value = true;
      }

      if (onlySpecialChars.hasMatch(text)) {
        contentError.value = null;
        hasRestrictedContent.value = false;
        isFormValid.value = false;
      } else {
        _checkRestrictedContent(text);
      }
    }
  }

    bool isContentNotChanged() {
    return originalContent == contentController.text.trim();
  }

    void setOriginalContent(String content) {
    originalContent = content;
    contentController.text = content;
    currentLength.value = content.length;
    updateFormValidity();
  }


  void _checkRestrictedContent(String text) {
    if (!_bannedWordsLoaded.value) {
      _loadBannedWords().then((_) => _performRestrictedContentCheck(text));
    } else {
      _performRestrictedContentCheck(text);
    }
  }

  void _performRestrictedContentCheck(String text) {
    final normalizedText = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final hasProfanity = _profanityFilter.hasProfanity(normalizedText);
    final hasBannedWords = _containsBannedWords(normalizedText);

    if (hasProfanity || hasBannedWords) {
      contentError.value = "Your post contains restricted content.";
      hasRestrictedContent.value = true;
      isFormValid.value = false;
    } else {
      contentError.value = null;
      hasRestrictedContent.value = false;
      isFormValid.value = true;
    }
  }

  Future<bool> checkAndResetBanIfNeeded() async {
    if (currentUid == null) return true;

    try {
      final userDoc = await db.collection('users').doc(currentUid).get();
      if (!userDoc.exists) return true;

      final data = userDoc.data() ?? {};
      final deletedCount = data['deletedPostsCount'] == null
          ? 0
          : (data['deletedPostsCount'] is int
                ? data['deletedPostsCount']
                : int.tryParse(data['deletedPostsCount'].toString()) ?? 0);

      if (deletedCount < 6) return true;

      final reachedSixAt = data['reachedSixAt'];
      if (reachedSixAt == null || reachedSixAt is! Timestamp) return true;

      final now = Timestamp.now();
      final elapsedSeconds = now.seconds - reachedSixAt.seconds;
      final elapsedDays = elapsedSeconds ~/ 86400;

      if (elapsedDays >= 14) {
        await db.collection('users').doc(currentUid).update({
          'deletedPostsCount': 0,
          'reachedSixAt': FieldValue.delete(),
        });
        return true;
      }

      return false;
    } catch (e) {
      print('Error checking ban status: $e');
      return true;
    }
  }

  Future<int?> getRemainingBanDays() async {
    if (currentUid == null) return null;

    try {
      final userDoc = await db.collection('users').doc(currentUid).get();
      if (!userDoc.exists) return null;

      final data = userDoc.data() ?? {};
      final deletedCount = data['deletedPostsCount'] == null
          ? 0
          : (data['deletedPostsCount'] is int
                ? data['deletedPostsCount']
                : int.tryParse(data['deletedPostsCount'].toString()) ?? 0);

      if (deletedCount < 6) return null;

      final reachedSixAt = data['reachedSixAt'];
      if (reachedSixAt == null || reachedSixAt is! Timestamp) return null;

      final now = Timestamp.now();
      final elapsedSeconds = now.seconds - reachedSixAt.seconds;
      final elapsedDays = elapsedSeconds ~/ 86400;

      if (elapsedDays >= 14) return null;

      return 14 - elapsedDays;
    } catch (e) {
      print('Error getting remaining ban days: $e');
      return null;
    }
  }

  Future<bool> addPost(BuildContext context) async {
    hasInteracted.value = true;

    updateFormValidity(markInteracted: false);

    if (!isFormValid.value) return false;

    var text = contentController.text.trim();
    //Remove leading/trailing spaces and collapse multiple spaces between words
    text = text.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (text.isEmpty) {
      ToastService.error("Post cannot be empty");
      return false;
    }

    if (currentUid == null) {
      ToastService.error("You must be logged in to create a post");
      return false;
    }

    if (!_bannedWordsLoaded.value) {
      await _loadBannedWords();
    }

    final hasProfanity = _profanityFilter.hasProfanity(text);
    final hasBannedWords = _containsBannedWords(text);

    if (hasProfanity || hasBannedWords) {
      return false;
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
      // print('Manually refreshing posts...');
      // await fetchPosts();
      print('Post added successfully with ID: ${docRef.id}');
      contentController.clear();
      // No need to fetchPosts(), the listener will update automatically
      return true;
    } catch (e) {
      ToastService.error("Could not add post. Try again!");
      return false;
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

  // Restored unsave functionality - removes saved post from user's savedPosts collection and updates reactive lists
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

  bool isPostLiked(String postId) => likedPostIds.contains(postId);
  int getLikeCount(String postId) => likeCounts[postId] ?? 0;


  Future<void> toggleLike(String postId) async {
    if (currentUid == null) {
      ToastService.error("You must be logged in to like posts");
      return;
    }
    try {
      if (_likeOpsInFlight.contains(postId)) return;
      _likeOpsInFlight.add(postId);

      final isLiked = isPostLiked(postId);
      final likesDocRef = db
          .collection(communityCollection)
          .doc(postId)
          .collection('likes')
          .doc(currentUid);

      if (isLiked) {
        await likesDocRef.delete();
        likedPostIds.remove(postId);
      } else {
        await likesDocRef.set({'createdAt': FieldValue.serverTimestamp()});
        likedPostIds.add(postId); //
      }
    } catch (e) {
      debugPrint('toggleLike error: $e');
    } finally {
      _likeOpsInFlight.remove(postId);
    }
  }

  void _setupLikesSubscriptions(List<QueryDocumentSnapshot> postDocs) {
    final currentIds = postDocs.map((d) => d.id).toSet();

    final toRemove = _likesSubscriptions.keys
        .where((id) => !currentIds.contains(id))
        .toList(growable: false);
    for (final id in toRemove) {
      _likesSubscriptions[id]?.cancel();
      _likesSubscriptions.remove(id);
      likeCounts.remove(id);
      likedPostIds.remove(id);
    }

    for (final doc in postDocs) {
      final postId = doc.id;
      if (_likesSubscriptions.containsKey(postId)) continue;

      final sub = db
          .collection(communityCollection)
          .doc(postId)
          .collection('likes')
          .snapshots()
          .listen(
            (likeSnap) {
              likeCounts[postId] = likeSnap.size;
              final uid = currentUid;
              if (uid != null) {
                final hasLiked = likeSnap.docs.any((d) => d.id == uid);
                if (hasLiked) {
                  if (!likedPostIds.contains(postId)) likedPostIds.add(postId);
                } else {
                  likedPostIds.remove(postId);
                }
              } else {
                likedPostIds.remove(postId);
              }
            },
            onError: (e) {
              debugPrint('likes listener error for post $postId: $e');
            },
          );

      _likesSubscriptions[postId] = sub;
    }
  }

  //Set up real-time listener for comments of a post
  void listenToComments(String postId) {
    // Cancel any existing subscription for this post
    _commentsSubscriptions[postId]?.cancel();

    print('Setting up comments listener for post: $postId');

    _commentsSubscriptions[postId] = db
        .collection(communityCollection)
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final commentList = snapshot.docs.map((doc) {
              final data = doc.data();
              return Comment(
                id: doc.id,
                content: data['content'] ?? '',
                userId: data['userId'] ?? '',
                userName: data['userName'] ?? '',
                createdAt: data['createdAt'] ?? Timestamp.now(),
                isReported: data['isReported'] ?? false,
              );
            }).toList();

            // Update reactive list for this post
            commentsForPost(postId).value = commentList;

            print('Fetched ${commentList.length} comments for post: $postId');
          },
          onError: (e) {
            print('Error listening to comments for post $postId: $e');
          },
        );
  }

  // Returns reactive comments list for a post
  RxList<Comment> commentsForPost(String postId) {
    if (!_commentsPerPost.containsKey(postId)) {
      _commentsPerPost[postId] = <Comment>[].obs;
    }
    return _commentsPerPost[postId]!;
  }

  // Report a comment
  Future<void> reportComment(String postId, String commentId) async {
    try {
      await db
          .collection(communityCollection)
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .update({'isReported': true});
      ToastService.success("Your report has been received.");

      print('Comment $commentId reported successfully for post $postId');
    } catch (e) {
      print('Failed to report comment $commentId: $e');
    }
  }

  // Report a Post
  Future<void> reportPost(String postId) async {
    try {
      await db.collection(communityCollection).doc(postId).update({
        'isReported': true,
      });

      ToastService.success("Your report has been received.");

      print('Comment $postId reported successfully for post $postId');
    } catch (e) {
      print('Failed to report comment $postId: $e');
    }
  }

Future<int> getCommentCount(String postId) async {
  final snapshot = await db
      .collection(communityCollection)
      .doc(postId)
      .collection('comments')
      .get();

  return snapshot.size;
}

  Future<bool> addComment(BuildContext context, String postId) async {
    hasInteracted.value = true;

    updateFormValidity(markInteracted: false);

    if (!isFormValid.value) return false;

    var text = contentController.text.trim();
    text = text.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (text.isEmpty) {
      ToastService.error("Comment cannot be empty");
      return false;
    }

    if (currentUid == null) {
      ToastService.error("You must be logged in to create a comment");
      return false;
    }

    if (!_bannedWordsLoaded.value) {
      await _loadBannedWords();
    }

    final hasProfanity = _profanityFilter.hasProfanity(text);
    final hasBannedWords = _containsBannedWords(text);

    if (hasProfanity || hasBannedWords) {
      return false;
    }

    try {
      isLoading.value = true;

      // Ensure user info is up to date
      await _updateCommunityCollection();

      final userDoc = await db.collection("users").doc(currentUid).get();

      final firstName = userDoc['firstName'] ?? '';
      final lastName = userDoc['lastName'] ?? '';
      final displayName = (firstName + ' ' + lastName).trim();

      final comment = Comment(
        id: '',
        content: text,
        userId: currentUid!,
        userName: displayName,
        createdAt: Timestamp.now(),
      );

      print(
        'Adding Comment to post subcollection: $communityCollection/$postId/comments',
      );
      final docRef = await db
          .collection(communityCollection)
          .doc(postId) 
          .collection("comments")
          .add(comment.toFirestore());

      await docRef.update({'id': docRef.id});

      contentController.clear();
      print("Comment added with ID: ${docRef.id}");

      return true;
    } catch (e) {
      print(e);
      ToastService.error("Could not add comment. Try again!");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deletePost(String postId) async {
    if (currentUid == null) return;

    try {
      // Ensure post belongs to current user
      final postDoc = await db
          .collection(communityCollection)
          .doc(postId)
          .get();
      if (postDoc.exists && postDoc['userId'] == currentUid) {
        await db.collection(communityCollection).doc(postId).delete();

        // Remove from reactive lists for immediate UI update
        posts.removeWhere((p) => p.id == postId);
        userPosts.removeWhere((p) => p.id == postId);
        savedPosts.removeWhere((p) => p.id == postId);
        savedPostIds.remove(postId);
      }
    } catch (e) {
      print('Error deleting post $postId: $e');
    }
  }


  String? originalContent; // store original content for edit
  Future<bool> updatePost(String postId, String newContent) async {
    try {
     isLoading.value = true;
     newContent = newContent.trim().replaceAll(RegExp(r'\s+'), ' ');
      await FirebaseFirestore.instance
          .collection(communityCollection)
          .doc(postId)
          .update({
            'content': newContent,
            'isEdited': true,
          });
      isLoading.value = false;
      refreshUserPostsListener();
      return true; 
    } catch (e) {
      isLoading.value = false;
      print("Error updating post: $e");
      return false; 
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await FirebaseFirestore.instance
          .collection(communityCollection)
          .doc(postId)
          .collection("comments")
          .doc(commentId)
          .delete();
    } catch (e) {
      print("Error deleting comment: $e");
    }
  }

  void _clearLikesSubscriptions() {
    for (final sub in _likesSubscriptions.values) {
      sub.cancel();
    }
    _likesSubscriptions.clear();
  }
}
