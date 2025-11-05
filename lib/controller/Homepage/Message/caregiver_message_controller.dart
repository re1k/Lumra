import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';
import 'package:lumra_project/model/Homepage/Message/CaregiverMessage.dart';

class CaregiverMessageController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final AuthController auth = Get.find<AuthController>();

  RxBool canSendMessage = false.obs;
  CaregiverMessage? lastMessage;

  Timer? _timer;
  Timer? _autoChecker;

  @override
  void onInit() {
    super.onInit();

    checkMessageStatus();

    // start a periodic checker every 1 minute
    _autoChecker = Timer.periodic(const Duration(minutes: 1), (_) async {
      await checkMessageStatus();
    });
  }

  ///  Check message status
  Future<void> checkMessageStatus() async {
    final caregiverId = auth.currentUser?.uid;
    if (caregiverId == null) return;

    final caregiverDoc = await _firestore
        .collection('users')
        .doc(caregiverId)
        .get();
    final linkedUserId = caregiverDoc.data()?['linkedUserId'];
    if (linkedUserId == null) return;

    final adhdDoc = await _firestore
        .collection('users')
        .doc(linkedUserId)
        .get();

    final msgData = adhdDoc.data()?['caregiverMessage'];

    if (msgData == null) {
      canSendMessage.value = true;
      lastMessage = null;
      return;
    }

    final isEmpty =
        msgData == null ||
        (msgData is Map &&
            ((msgData['text'] == null ||
                    msgData['text'].toString().trim().isEmpty) &&
                (msgData['timestamp'] == null)));

    if (isEmpty) {
      await _firestore.collection('users').doc(linkedUserId).update({
        'caregiverMessage': FieldValue.delete(),
      });
      canSendMessage.value = true;
      lastMessage = null;
      return;
    }

    lastMessage = CaregiverMessage.fromMap(Map<String, dynamic>.from(msgData));
    final lastTime =
        DateTime.tryParse(lastMessage!.timestamp) ?? DateTime.now();
    final diff = DateTime.now().difference(lastTime);

    if (diff.inMinutes >= 24 * 60) {
      await _firestore.collection('users').doc(linkedUserId).update({
        'caregiverMessage': FieldValue.delete(),
      });
      canSendMessage.value = true;
      lastMessage = null;
      return;
    } else {
      canSendMessage.value = false;
    }
  }

  Future<void> sendMessage(String text) async {
    final caregiverId = auth.currentUser?.uid;
    if (caregiverId == null) return;

    final caregiverDoc = await _firestore
        .collection('users')
        .doc(caregiverId)
        .get();
    final linkedUserId = caregiverDoc.data()?['linkedUserId'];
    if (linkedUserId == null || linkedUserId.isEmpty) return;
    final msg = CaregiverMessage(
      text: text,
      timestamp: DateTime.now().toIso8601String(),
    );

    await _firestore.collection('users').doc(linkedUserId).set({
      'caregiverMessage': {
        'text': msg.text,
        'timestamp': msg.timestamp,
        'opened': false, //
      },
    }, SetOptions(merge: true));

    canSendMessage.value = false;
    lastMessage = msg;

    _timer?.cancel();
    _timer = Timer(const Duration(hours: 24), () {
      canSendMessage.value = true;
      lastMessage = null;
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    _autoChecker?.cancel();
    super.onClose();
  }
}
