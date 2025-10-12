import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lumra_project/controller/ChatBoot/AdhdChatBootController.dart';
import 'package:lumra_project/controller/Activity/ActivityController.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final ChatController controller = Get.find<ChatController>();
  late final Activitycontroller activityController;

  //final List<types.Message> _messages = [];

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

  late final AnimationController _waveCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void initState() {
    super.initState();
    activityController = Get.isRegistered<Activitycontroller>()
        ? Get.find<Activitycontroller>()
        : Get.put<Activitycontroller>(
            Activitycontroller(FirebaseFirestore.instance),
            permanent: true,
          );
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  // SEND FLOW
  Future<void> _handleSend(types.PartialText message) async {
    // 1) user's message
    final userMsg = types.TextMessage(
      id: Random().nextInt(999999).toString(),
      author: _user,
      text: message.text,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    setState(() => _messages.insert(0, userMsg));

    controller.chatHistory.insert(0, {
      // new
      'id': userMsg.id,
      'author': 'user',
      'text': userMsg.text,
      'createdAt': userMsg.createdAt,
    });

    // 2) typing indicator
    final typingMsg = types.TextMessage(
      id: 'typing',
      author: _bot,
      text: '...',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    setState(() => _messages.insert(0, typingMsg));

    // 3) ask Gemini
    final replyText = await controller.sendMessage(message.text);

    // 4) remove typing
    setState(() => _messages.removeWhere((m) => m.id == 'typing'));

    // 5) add bot message
    final botMsg = types.TextMessage(
      id: Random().nextInt(999999).toString(),
      author: _bot,
      text: replyText,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    setState(() => _messages.insert(0, botMsg));

    controller.chatHistory.insert(0, {
      // new
      'id': botMsg.id,
      'author': 'bot',
      'text': botMsg.text,
      'createdAt': botMsg.createdAt,
    });

    // 6) auto-save suggestions
    final savedCount = await _autoSaveSuggestions(replyText);
    if (savedCount > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added $savedCount activit${savedCount == 1 ? "y" : "ies"}',
          ),
        ),
      );
    }
  }

  // PARSE & SAVE
  // 1) MUCH more permissive extractor
  // Known categories in your app (
  final Set<String> _knownCats = {
    'mindfulness',
    'creative',
    'learning',
    'sport',
    'sports',
    'relaxation',
    'social / community',
    'motivation / goal setting',
    'activity',
  };

  // Normalize to the labels your UI expects
  String _normalizeCategory(String raw) {
    final k = raw.trim().toLowerCase();
    if (k == 'sports' || k == 'sport') return 'Sport';
    if (k == 'mindfulness') return 'Mindfulness';
    if (k == 'creative') return 'Creative';
    if (k == 'learning') return 'Learning';
    if (k == 'relaxation') return 'Relaxation';
    if (k == 'social / community') return 'Social / Community';
    if (k == 'motivation / goal setting') return 'Motivation / Goal Setting';
    if (k == 'activity') return 'Activity';
    // Default: Title-case the raw string
    final s = raw.trim();
    return s.isEmpty ? 'Activity' : s[0].toUpperCase() + s.substring(1);
  }

  // Safer extractor:
  // • Accepts -, –, —, •, *, "1." bullets
  // • Extracts time anywhere in the line
  // • Only treats the left side as "category" when:
  //     - there's a colon "Category: Title", OR
  //     - there is a dash and the left side is a known category
  List<Map<String, String>> _extractSuggestions(String text) {
    final bullet = RegExp(r'^\s*(?:[-–—•*]|\d+[\.)])\s+(.+)$', multiLine: true);
    final dashOrColon = RegExp(r'\s[:]\s|\s[-–—]\s');

    final out = <Map<String, String>>[];

    for (final m in bullet.allMatches(text)) {
      var line = m.group(1)!.trim();
      line = line.replaceAll(RegExp(r'\([^)]*\)'), '').trim(); // شيل الأقواس

      String category = 'Activity';
      String title = line;

      final split = dashOrColon.firstMatch(line);
      if (split != null) {
        final left = line.substring(0, split.start).trim();
        final right = line.substring(split.end).trim();
        const known = {
          'mindfulness',
          'creative',
          'learning',
          'sport',
          'sports',
          'relaxation',
          'social / community',
          'motivation / goal setting',
          'activity',
        };
        final isColon = line.substring(split.start, split.end).contains(':');
        if (isColon || known.contains(left.toLowerCase())) {
          category = left;
          title = right;
        } else {
          title = left;
        }
      }

      out.add({'title': title, 'category': category});
    }

    return out;
  }

  Future<int> _autoSaveSuggestions(String replyText) async {
    // USE the same controller instance you created in this widget.
    final chatCtrl = controller;

    // If we have canonical picks from JSON, save those and skip parsing
    if (chatCtrl.lastSuggested.isNotEmpty) {
      int saved = 0;
      for (final a in chatCtrl.lastSuggested) {
        try {
          await activityController.addSuggestedActivity(
            title: (a['title'] ?? '').trim(),
            category: (a['category'] ?? 'Activity').trim(),
            description: (a['description'] ?? '').trim(),
            time: (a['time'] ?? '').trim(),
          );
          saved++;
        } catch (e) {
          debugPrint('Save failed: $e');
        }
      }
      // Clear after saving so we don’t duplicate on next message مهمممة
      chatCtrl.lastSuggested = [];
      return saved;
    }

    return 0;
  }

  // 2) Save-and-log: shows what was parsed & saved
  // Future<int> _autoSaveSuggestions(String replyText) async {
  //   final items = _extractSuggestions(replyText);

  //   // DEBUG LOG: see parsed suggestions in your console
  //   // (You can remove these prints once confirmed)
  //   // ignore: avoid_print
  //   print('Parsed ${items.length} suggestion(s):');
  //   for (final a in items) {
  //     print(' - [${a['category']}] ${a['title']}  (${a['time']})');
  //   }

  //   int saved = 0;
  //   for (final a in items) {
  //     try {
  //       await activityController.addSuggestedActivity(
  //         title: a['title']!,
  //         category: a['category']!,
  //         description: a['description']!,
  //         time: (a['time'] ?? '').trim(),
  //       );

  //       saved++;
  //     } catch (e) {
  //       // ignore: avoid_print
  //       print('Save failed: $e'); // helps spot Firestore errors if any
  //     }
  //   }

  //   // DEBUG LOG
  //   // ignore: avoid_print
  //   print('Saved $saved suggestion(s).');
  //   return saved;
  // }

  // ---------- UI ----------
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

                //  Chat area + composer
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

                        inputBackgroundColor: Colors.white,
                        inputTextColor: Colors.black87,
                        inputTextStyle: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        inputPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        inputContainerDecoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: BColors.primary.withOpacity(0.6),
                            width: 1.6,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: BColors.primary.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        sendButtonIcon: const Icon(
                          Icons.send_rounded,
                          color: BColors.primary,
                          size: 22,
                        ),
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

//  Animated wave clipper
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
