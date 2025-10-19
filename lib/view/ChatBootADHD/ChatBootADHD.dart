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
import 'package:lumra_project/theme/base_themes/sizes.dart';

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

    final title = (data['title'] ?? '').toString().trim();
    final category = _normalizeCategory((data['category'] ?? '').toString());
    if (title.isEmpty) return;

    try {
      // 1) de-dupe against both user activities and visible initial activities
      final dup = await _isAlreadyInActivitiesTab(
        uid: uid,
        title: title,
        category: category,
      );
      if (dup) {
        debugPrint('🔁 Skip storing duplicate activity: [$category] $title');
        return;
      }

      // 2) write with a stable dedupeKey for future quick lookups
      final dedupeKey = _dedupeKey(title, category);
      final payload = {
        ...data,
        'title': title,
        'category': category,
        'dedupeKey': dedupeKey,
        'isInitial': false, // chatbot-suggested
        'createdAt': FieldValue.serverTimestamp(),
        // keep isChecked/checkedAt/expireAt from data (default: false/null/null)
      };

      final ref = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('activities')
          .add(payload);

      debugPrint('✅ stored activity: ${ref.id}');
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
  bool _showDots = false;
  Future<void> _handleSend(types.PartialText message) async {
    if (message.text.trim().isEmpty) return; // block empty sends

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
    setState(() => _showDots = true); // show dots immediately

    // 2️⃣ Wait for Gemini reply (logic unchanged)
    final replyText = await controller.sendMessage(message.text);

    // 3️⃣ Hide dots after getting reply
    if (!mounted) return;
    setState(() => _showDots = false);

    // 2) typing
    // final typingMsg = types.TextMessage(
    //   id: 'typing',
    //   author: _bot,
    //   text: '...',
    //   createdAt: DateTime.now().millisecondsSinceEpoch,
    // );
    // setState(() => _messages.insert(0, typingMsg));

    // // 3) Gemini reply
    // final replyText = await controller.sendMessage(message.text);

    // // 4) remove typing
    // setState(() => _messages.removeWhere((m) => m.id == 'typing'));

    // 5) bot message -> UI + history
    // 4️⃣ Bot message → UI + history
    final botMsg = types.TextMessage(
      id: Random().nextInt(999999).toString(),
      author: _bot,
      text: replyText,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    setState(
      () => controller.chatHistory.insert(0, {
        'id': botMsg.id,
        'author': 'bot',
        'text': botMsg.text,
        'createdAt': botMsg.createdAt,
      }),
    );

    // 6) STORE (no retrieval here)
    await _autoSaveSuggestions();
    // final savedCount = await _autoSaveSuggestions(); //we can delete it
    // if (!mounted) return;
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
            width: 380,
            height: 680,
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
                //Animated wave header
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
                          height: 56,
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
                // 2) encouragement message just below the header
                // Padding(
                //   padding: const EdgeInsets.only(top: 8),
                //   child: const _EncouragementCard(
                //     // text: 'Remember, I am here for your in-the-moment feelings',
                //     text: 'Here for your moment feelings',
                //     maxWidth: 320, //  set width here
                //     backgroundColor: BColors.white,
                //   ),
                // ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 0,
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 300,
                      height: 30,
                      child: const _EncouragementCard(
                        text: 'Here for your moment feelings.',
                        maxWidth: 340,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),

                // ──  Add this divider or gradient line
                Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [BColors.primary, BColors.secondry],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
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

                    child: Stack(
                      children: [
                        Chat(
                          messages: _messages,
                          onSendPressed: _handleSend,
                          user: _user,
                          typingIndicatorOptions: TypingIndicatorOptions(
                            typingUsers: _showDots
                                ? const [
                                    types.User(id: 'lumra', firstName: 'Lumra'),
                                  ]
                                : const [],
                          ),

                          theme: DefaultChatTheme(
                            backgroundColor: Colors.white,
                            primaryColor: BColors.primary,

                            messageBorderRadius: 14,
                            sentMessageBodyTextStyle: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                            //DO NOT DELETE ANYTHING UNTIL WE DECIDE
                            // typingIndicatorTheme: TypingIndicatorTheme(
                            //   // REQUIRED in your version:
                            //   animatedCirclesColor:
                            //       BColors.primary, // dots color
                            //   animatedCircleSize: 3, // dots size (px)
                            //   bubbleBorder: BorderRadius.circular(
                            //     14,
                            //   ), // bubble radius
                            //   bubbleColor: const Color(0xFFF1F2F4),
                            //   countAvatarColor: const Color(0xFFF1F2F4),
                            //   countTextColor: const Color(0xFFF1F2F4),
                            //   multipleUserTextStyle: TextStyle(), // bubble bg
                            //   // Optional in many versions, but add to hide the text:
                            //   // textStyle: const TextStyle(color: Colors.white),// makes “Lumra is typing…” invisible on white
                            // ),
                            receivedMessageBodyTextStyle: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                            inputBackgroundColor: Colors.transparent,
                            inputContainerDecoration: const BoxDecoration(),
                            inputTextColor: Colors.black87,
                            inputTextStyle: const TextStyle(
                              fontSize: 15,
                              height: 1.4,
                            ),
                            inputPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
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
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(18),
                                ),
                                borderSide: BorderSide(
                                  color: Color.fromARGB(255, 160, 160, 160),
                                  width: 1.2,
                                ),
                              ),
                            ),
                            sendButtonIcon: Icon(
                              Icons.send_rounded,
                              color: _inputCtrl.text.trim().isEmpty
                                  ? Colors
                                        .grey
                                        .shade400 // disabled look
                                  : BColors.buttonPrimary, // active color
                              size: 24,
                            ),
                          ),
                          onAttachmentPressed: null,
                          inputOptions: InputOptions(
                            textEditingController: _inputCtrl,
                            sendButtonVisibilityMode: SendButtonVisibilityMode
                                .always, // always visible
                          ),
                          l10n: const ChatL10nEn(
                            emptyChatPlaceholder:
                                "No chats yet, but I’m here whenever you’re ready.",
                            inputPlaceholder: "Write your message...",
                          ),
                        ),

                        ///here is the 3 dots
                        // if (_showDots)
                        //   const Positioned(
                        //     left: 16,
                        //     bottom: 65, // adjust to sit above the input
                        //     child: _TypingDotsBubble(),
                        //   ),
                      ],
                    ),
                    // DO NOT REMOVE THIS COMMENT/////////////////////////////
                    // I don’t trust the chatbot anymore 😭
                    // child: Chat(
                    //   messages: _messages,
                    //   onSendPressed: _handleSend,
                    //   user: _user,
                    //   theme: DefaultChatTheme(
                    //     backgroundColor: Colors.white,
                    //     primaryColor: BColors.primary,
                    //     messageBorderRadius: 14,
                    //     sentMessageBodyTextStyle: const TextStyle(
                    //       fontSize: 15,
                    //       color: Colors.white,
                    //     ),
                    //     receivedMessageBodyTextStyle: const TextStyle(
                    //       fontSize: 15,
                    //       color: Colors.black87,
                    //     ),

                    //     // background
                    //     inputBackgroundColor: Colors.transparent,
                    //     inputContainerDecoration:
                    //         const BoxDecoration(), // remove outer border completely, shall we change it?
                    //     // Style text input only
                    //     inputTextColor: Colors.black87,
                    //     inputTextStyle: const TextStyle(
                    //       fontSize: 15,
                    //       height: 1.4,
                    //     ),
                    //     inputPadding: const EdgeInsets.symmetric(
                    //       horizontal: 12,
                    //       vertical: 8,
                    //     ),

                    //     // line border
                    //     inputTextDecoration: InputDecoration(
                    //       hintText: 'Write your message...',
                    //       hintStyle: TextStyle(color: Colors.grey.shade500),
                    //       contentPadding: const EdgeInsets.symmetric(
                    //         horizontal: 14,
                    //         vertical: 10,
                    //       ),
                    //       filled: true,
                    //       fillColor: Colors.white,
                    //       border: OutlineInputBorder(
                    //         borderRadius: BorderRadius.circular(24),
                    //         borderSide: BorderSide(
                    //           color: Colors.grey.shade300,
                    //           width: 1,
                    //         ),
                    //       ),
                    //       enabledBorder: OutlineInputBorder(
                    //         borderRadius: BorderRadius.circular(24),
                    //         borderSide: BorderSide(
                    //           color: Colors.grey.shade300,
                    //           width: 1,
                    //         ),
                    //       ),
                    //       //INPUT FIELD BORDER
                    //       focusedBorder: OutlineInputBorder(
                    //         borderRadius: BorderRadius.circular(18),
                    //         borderSide: const BorderSide(
                    //           color: Color.fromARGB(255, 160, 160, 160),
                    //           width: 1.2,
                    //         ),
                    //       ),
                    //     ),

                    //     //  send arrow
                    //     sendButtonIcon: const Icon(
                    //       Icons.send_rounded,
                    //       color: BColors.buttonPrimary,
                    //       size: 24,
                    //     ),
                    //   ),

                    //   // Remove upload icon
                    //   onAttachmentPressed: null,

                    //   // Behavior of input
                    //   inputOptions: InputOptions(
                    //     textEditingController:
                    //         _inputCtrl, // attach our controller
                    //     sendButtonVisibilityMode:
                    //         SendButtonVisibilityMode.editing,
                    //     autocorrect: true,
                    //     enableSuggestions: true,
                    //   ),

                    //   //  Empty chat placeholder////////////////////////
                    //   l10n: const ChatL10nEn(
                    //     emptyChatPlaceholder:
                    //         "No chats yet, but I’m here whenever you’re ready.",
                    //     inputPlaceholder: "Write your message...",
                    //   ),
                    // ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // DEDUPE HELPERS
  String _norm(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  String _dedupeKey(String title, String category) =>
      '${_norm(category)}|${_norm(title)}';

  // Query: an active user activity with the same dedupeKey exists?
  Future<bool> _userActivityExists(String uid, String key) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('activities')
        .where('dedupeKey', isEqualTo: key)
        .limit(5)
        .get();

    final now = DateTime.now();
    for (final d in snap.docs) {
      final data = d.data();
      final ts = data['expireAt'];
      final expired = (ts is Timestamp) && ts.toDate().isBefore(now);
      if (!expired) return true; // found active duplicate
    }
    return false;
  }

  // Initial templates, copied from ActivityController logic
  Future<List<Map<String, dynamic>>> _loadInitialTemplatesBandFiltered(
    String uid,
  ) async {
    final db = FirebaseFirestore.instance;

    // 1) points
    final userDoc = await db.collection('users').doc(uid).get();
    final int totalPoints = (userDoc.data()?['totalPoints'] ?? 0) as int;

    // 2) all templates
    final tplSnap = await db.collection('initialActivities').get();
    final all = tplSnap.docs
        .map(
          (doc) => {
            'id': doc.id,
            'title': (doc.data()['title'] ?? '').toString(),
            'description': (doc.data()['description'] ?? '').toString(),
            'category': (doc.data()['category'] ?? '').toString(),
            'time': (doc.data()['time'] ?? '').toString(),
          },
        )
        .toList();

    // 3) same band filters you use currently
    List<String> titlesBand = [];
    if (totalPoints >= 5 && totalPoints <= 8) {
      titlesBand = ['Short Walk', 'Light Yoga', 'Small Art'];
    } else if (totalPoints >= 9 && totalPoints <= 12) {
      titlesBand = ['Short Run', 'Brain Games', 'Cooking'];
    } else if (totalPoints >= 13 && totalPoints <= 16) {
      titlesBand = ['Team sports', 'Fun Exercises', 'Journaling'];
    } else if (totalPoints >= 17 && totalPoints <= 20) {
      titlesBand = ['Advanced Yoga', 'Large Puzzle', 'Gardening'];
    }

    final filtered = titlesBand.isNotEmpty
        ? all.where((a) => titlesBand.contains(a['title']?.trim())).toList()
        : all;

    return filtered;
  }

  // Is there an initial activity with same (title, category) that is *currently visible* in the tab?
  //ASK LOBA AND LATIFA IF WE NEED IT OR NOT
  Future<bool> _initialVisibleDuplicate(
    String uid,
    String title,
    String category,
  ) async {
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();
    final candidates = await _loadInitialTemplatesBandFiltered(uid);
    // find any template matching title+category (case-insensitive)
    final match = candidates.firstWhere(
      (a) =>
          _norm(a['title'] ?? '') == _norm(title) &&
          _norm(a['category'] ?? '') == _norm(category),
      orElse: () => {},
    );
    if (match.isEmpty) return false;

    final String templateId = match['id'] as String;

    // Read the user's status for this template
    final status = await db
        .collection('users')
        .doc(uid)
        .collection('activityStatus')
        .doc(templateId)
        .get();

    if (!status.exists) {
      // Fresh initial template without status ->it IS visible
      return true;
    }

    final data = status.data() ?? {};
    final bool isChecked = (data['isChecked'] ?? false) as bool;
    final Timestamp? ts = data['expireAt'] is Timestamp
        ? data['expireAt'] as Timestamp
        : null;
    final bool expired = ts != null && ts.toDate().isBefore(now);

    // In your UI, an initial item is shown unless (checked && expired).
    final isVisible = !(isChecked && expired);
    return isVisible;
  }

  // Combined: is this activity already visible (user doc OR initial list)?// ASK team
  Future<bool> _isAlreadyInActivitiesTab({
    required String uid,
    required String title,
    required String category,
  }) async {
    final key = _dedupeKey(title, category);
    final userDup = await _userActivityExists(uid, key);
    return userDup; // only block if user already has a chatbot activity (not initials)
  }
}

// --- typing dots bubble
class _TypingDotsBubble extends StatefulWidget {
  const _TypingDotsBubble({super.key});

  @override
  State<_TypingDotsBubble> createState() => _TypingDotsBubbleState();
}

class _TypingDotsBubbleState extends State<_TypingDotsBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget dot(int i) => FadeTransition(
      opacity: Tween(begin: 0.25, end: 1.0)
          .chain(CurveTween(curve: Curves.easeInOut))
          .animate(DelayTween(i * 0.2).animate(_c)),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 3),
        child: CircleAvatar(radius: 3, backgroundColor: Color(0xFF6B6F76)),
      ),
    );

    return Align(
      alignment: Alignment.centerLeft, // bot side
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F2F4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [dot(0), dot(1), dot(2)],
        ),
      ),
    );
  }
}

class DelayTween extends Tween<double> {
  final double delay;
  DelayTween(this.delay) : super(begin: 0, end: 1);
  @override
  double transform(double t) => ((t + (1 - delay)) % 1);
}

// ── Inline encouragement card
class _EncouragementCard extends StatelessWidget {
  final String text;
  final double maxWidth;
  final Color backgroundColor; // new
  const _EncouragementCard({
    super.key,
    this.text = 'Remember, I am here for your in-the-moment-feelings',
    this.maxWidth = 340,
    this.backgroundColor = BColors.white,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          color: backgroundColor, //  background control
          padding: const EdgeInsets.fromLTRB(9, 0, 9, 3), ///////
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: BColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: tt.bodyMedium?.copyWith(
                    color: const Color.fromARGB(255, 91, 91, 91),
                    fontWeight: FontWeight.normal, //normal
                    fontSize: 12,
                  ),
                ),
              ),
            ],
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
