import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';

class AdhdMessageController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final _auth = Get.find<AuthController>();

  final hasMessage = false.obs;
  final isNewMessage = false.obs;
  final messageText = ''.obs;
  RxBool isOpened = false.obs;

  void toggleOpened() {
    isOpened.value = !isOpened.value;
    if (isOpened.value) {
      isNewMessage.value = false;
    }
  }

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  Timer? _autoChecker;

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) throw Exception('No user');
    return u.uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_uid);

  @override
  void onInit() {
    super.onInit();

    _sub = _userDoc.snapshots().listen((snap) {
      final data = snap.data() ?? {};
      final cgMsg = data['caregiverMessage'];
      final isEmpty =
          cgMsg == null ||
          (cgMsg is Map &&
              ((cgMsg['text'] == null ||
                      cgMsg['text'].toString().trim().isEmpty) &&
                  (cgMsg['timestamp'] == null)));
      final opened = (cgMsg?['opened'] ?? false) == true;

      if (isEmpty) {
        hasMessage.value = false;
        isNewMessage.value = false;
        messageText.value = '';
        _userDoc.update({'caregiverMessage': FieldValue.delete()});
        return;
      }

      if (cgMsg != null && cgMsg['timestamp'] != null) {
        final msgTime =
            DateTime.tryParse(cgMsg['timestamp'].toString()) ?? DateTime.now();
        final diff = DateTime.now().difference(msgTime);

        if (diff.inHours >= 24) {
          _userDoc.update({'caregiverMessage': FieldValue.delete()});
          hasMessage.value = false;
          isNewMessage.value = false;
          messageText.value = '';
          return;
        }
      }

      hasMessage.value = true;
      messageText.value = (cgMsg['text'] ?? '').toString();
      isNewMessage.value = !opened;
    });

    _autoChecker = Timer.periodic(const Duration(minutes: 1), (_) async {
      final snap = await _userDoc.get();
      final data = snap.data() ?? {};
      final cgMsg = data['caregiverMessage'];
      if (cgMsg != null && cgMsg['timestamp'] != null) {
        final msgTime =
            DateTime.tryParse(cgMsg['timestamp'].toString()) ?? DateTime.now();
        final diff = DateTime.now().difference(msgTime);
        if (diff.inHours >= 24) {
          await _userDoc.update({'caregiverMessage': FieldValue.delete()});
          hasMessage.value = false;
          isNewMessage.value = false;
          messageText.value = '';
        }
      }
    });
  }

  Future<void> markOpened() async {
    try {
      await _userDoc.update({'caregiverMessage.opened': true});
      isNewMessage.value = false;
    } catch (e) {
      print("Error updating opened flag: $e");
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    _autoChecker?.cancel();
    super.onClose();
  }
}
