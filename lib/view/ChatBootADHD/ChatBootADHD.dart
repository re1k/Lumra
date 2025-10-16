import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:lumra_project/controller/ChatBoot/AdhdChatBootController.dart';
import 'package:lumra_project/model/Activity/ActivityModel.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/controller/ChatBoot/baseController.dart';

class ChatView extends StatefulWidget {
  final BaseChatController controller;
  const ChatView({super.key, required this.controller});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  BaseChatController get controller => widget.controller;

  // final BaseChatController controller = Get.find<BaseChatController>();

  // Build messages from controller.chatHistory
  List<types.Message> get _messages => controller.chatHistory
      .map(
        (e) => types.TextMessage(
          id: e['id'],
          author: e['author'] == 'user'
              ? const types.User(id: 'user')
              : const types.User(id: 'lumra'),
          text: e['text'],
          createdAt: e['createdAt'],
        ),
      )
      .toList();

  final _user = const types.User(id: 'user');
  final _bot = const types.User(id: 'lumra');
  final TextEditingController _inputCtrl = TextEditingController();

  late final AnimationController _waveCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _inputCtrl.addListener(() {
      // rebuild input when the first char is entered or removed
      setState(() {});
    });
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  // HELPERS: STORE ONLY

  String? _currentUid() => FirebaseAuth.instance.currentUser?.uid;

  String _normalizeCategory(String raw) {
    final k = raw.trim().toLowerCase();
    if (k == 'sports' || k == 'sport') return 'Sport';
    if (k == 'mindfulness') return 'Mindfulness';
    if (k == 'creative') return 'Creative';
    if (k == 'learning') return 'Learning';
    if (k == 'relaxation') return 'Relaxation';
    if (k == 'social / community') return 'Social / Community';
    if (k == 'motivation / goal setting') return 'Motivation / Goal Setting';
    if (k.isEmpty) return 'Activity';
    final s = raw.trim();
    return s.isEmpty ? 'Activity' : s[0].toUpperCase() + s.substring(1);
  }

  Future<void> _storeActivity(Map<String, dynamic> data) async {
    final uid = _currentUid();
    if (uid == null) {
      debugPrint('⛔️ Skip store: no signed-in user.');
      return;
    }
    try {
      final ref = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('activities')
          .add({
            ...data,
            'isInitial': false, // chatbot-suggested
            'createdAt': FieldValue.serverTimestamp(),
          });
      debugPrint('✅ stored activity: ${ref.id}'); ///// easier for us
    } catch (e, st) {
      debugPrint('🔥 Firestore write failed: $e');
      debugPrint(st.toString());
    }
  }

  Future<int> _autoSaveSuggestions() async {
    // Only ADHD bot stores activities
    if (controller is! AdhdChatController) return 0;
    final adhd = controller as AdhdChatController;

    final picks = adhd.lastSuggested;
    if (picks.isEmpty) return 0;

    int saved = 0;
    for (final a in picks) {
      try {
        final activity = Activitymodel(
          title: (a['title'] ?? '').trim(),
          category: _normalizeCategory(a['category'] ?? 'Activity'),
          description: (a['description'] ?? '').trim(),
          time: (a['time'] ?? '').trim(),
        );
        await _storeActivity(activity.toUserActivityJson());
        saved++;
      } catch (e) {
        debugPrint('Save failed: $e');
      }
    }
    adhd.lastSuggested = []; // avoid duplicates on next message
    return saved;
  }

  // SEND FLOW

  Future<void> _handleSend(types.PartialText message) async {
    // 1) user message -> UI + history
    final userMsg = types.TextMessage(
      id: Random().nextInt(999999).toString(),
      author: _user,
      text: message.text,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    setState(() => _messages.insert(0, userMsg));
    controller.chatHistory.insert(0, {
      'id': userMsg.id,
      'author': 'user',
      'text': userMsg.text,
      'createdAt': userMsg.createdAt,
    });

    // 2) typing
    final typingMsg = types.TextMessage(
      id: 'typing',
      author: _bot,
      text: '...',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    setState(() => _messages.insert(0, typingMsg));

    // 3) Gemini reply
    final replyText = await controller.sendMessage(message.text);

    // 4) remove typing
    setState(() => _messages.removeWhere((m) => m.id == 'typing'));

    // 5) bot message -> UI + history
    final botMsg = types.TextMessage(
      id: Random().nextInt(999999).toString(),
      author: _bot,
      text: replyText,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    setState(() => _messages.insert(0, botMsg));
    controller.chatHistory.insert(0, {
      'id': botMsg.id,
      'author': 'bot',
      'text': botMsg.text,
      'createdAt': botMsg.createdAt,
    });

    // 6) STORE (no retrieval here)
    final savedCount = await _autoSaveSuggestions();
    if (!mounted) return;
    /* if (savedCount > 0) {  no need 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added $savedCount activit${savedCount == 1 ? "y" : "ies"}',
          ),
        ),
      );
    } */
  }

  // UI

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Theme(
      data: Theme.of(context).copyWith(hintColor: Colors.black54),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            width: 360,
            height: 520,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: BColors.primary.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Animated wave header
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: AnimatedBuilder(
                    animation: _waveCtrl,
                    builder: (context, _) {
                      return ClipPath(
                        clipper: _AnimatedWaveClipper(phase: _waveCtrl.value),
                        clipBehavior: Clip.antiAlias,
                        child: Container(
                          height: 76,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [BColors.primary, BColors.secondry],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Lumra Assistant',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Chat area + composer
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: BColors.primary.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, -1),
                        ),
                      ],
                    ),
                    child: Chat(
                      messages: _messages,
                      onSendPressed: _handleSend,
                      user: _user,
                      theme: DefaultChatTheme(
                        backgroundColor: Colors.white,
                        primaryColor: BColors.primary,
                        messageBorderRadius: 14,
                        sentMessageBodyTextStyle: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                        ),
                        receivedMessageBodyTextStyle: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),

                        // background
                        inputBackgroundColor: Colors.transparent,
                        inputContainerDecoration:
                            const BoxDecoration(), // remove outer border completely, shall we change it?
                        // Style text input only
                        inputTextColor: Colors.black87,
                        inputTextStyle: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                        ),
                        inputPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),

                        // line border
                        inputTextDecoration: InputDecoration(
                          hintText: 'Write your message...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          //INPUT FIELD BORDER
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: Color.fromARGB(255, 160, 160, 160),
                              width: 1.2,
                            ),
                          ),
                        ),

                        //  send arrow
                        sendButtonIcon: const Icon(
                          Icons.send_rounded,
                          color: BColors.buttonPrimary,
                          size: 24,
                        ),
                      ),

                      // Remove upload icon
                      onAttachmentPressed: null,

                      // Behavior of input
                      inputOptions: InputOptions(
                        textEditingController:
                            _inputCtrl, // attach our controller
                        sendButtonVisibilityMode:
                            SendButtonVisibilityMode.editing,
                        autocorrect: true,
                        enableSuggestions: true,
                      ),

                      //  Empty chat placeholder////////////////////////
                      l10n: const ChatL10nEn(
                        emptyChatPlaceholder:
                            "No chats yet, but I’m here whenever you’re ready.",
                        inputPlaceholder: "Write your message...",
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Wave clipper

class _AnimatedWaveClipper extends CustomClipper<Path> {
  final double phase; // 0..1
  const _AnimatedWaveClipper({required this.phase});

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;

    const waveHeight = 16.0;
    const baseDrop = 12.0;
    final t = phase * 2 * 3.1415926535;

    final shift = (w * 0.12) * (0.5 + 0.5 * sin(t));

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, h - baseDrop);

    final c1 = Offset(
      w * 0.25 + shift * 0.5,
      h - baseDrop - waveHeight * (0.6 + 0.4 * sin(t)),
    );
    final p1 = Offset(w * 0.50, h - baseDrop);

    final c2 = Offset(
      w * 0.75 - shift,
      h - baseDrop + waveHeight * (0.6 + 0.4 * cos(t)),
    );
    final p2 = Offset(w, h - baseDrop);

    path
      ..quadraticBezierTo(c1.dx, c1.dy, p1.dx, p1.dy)
      ..quadraticBezierTo(c2.dx, c2.dy, p2.dx, p2.dy)
      ..lineTo(w, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant _AnimatedWaveClipper oldClipper) =>
      oldClipper.phase != phase;
}
