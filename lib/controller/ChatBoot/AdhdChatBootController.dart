// lib/controller/ChatBoot/AdhdChatBootController.dart
import 'dart:convert';
import 'dart:math';
import 'package:get/get.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:lumra_project/theme/base_themes/api_constants.dart';
import 'baseController.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdhdChatController extends BaseChatController {
  String? userName;
  void setUserName(String? name) {
    // to use the yser name in the chat

    final n = name?.trim();
    userName = (n == null || n.isEmpty) ? null : n;

    print(userName);
  }

  List<dynamic>? _cases; // JSON data
  final Random _rng = Random();

  /// Stores the last two selected activities from JSON,
  /// each element: {title, category, description, time}
  List<Map<String, String>> lastSuggested = [];
  // Tracks which activities have already been shown per mental state (in-memory per session)
  final Map<String, Set<String>> _usedActivitiesByState = {};

  List<Map<String, dynamic>> chatHistory = [];

  @override
  void onInit() {
    super.onInit();
    Gemini.init(apiKey: APIsConstants.Gimini_API, enableDebugging: true);
    _loadJsonCases();

    if (Get.isRegistered<AuthController>()) {
      final authCtrl = Get.find<AuthController>();
      final user = authCtrl.currentUser;

      if (user != null) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).get().then(
          (doc) {
            final name = doc.data()?['firstName'];
            if (name != null && name.toString().trim().isNotEmpty) {
              setUserName(name);
              print("🔹 Loaded user name from AuthController: $name");
            }
          },
        );
      }
    }
  }

  Future<void> _loadJsonCases() async {
    try {
      final data = await rootBundle.loadString(
        'assets/adhd_cases/AdhdActivites.json',
      );
      _cases = json.decode(data) as List<dynamic>;
    } catch (_) {
      _cases = null;
    }
  }

  Future<void> ensureJsonLoaded() async {
    if (_cases == null) await _loadJsonCases();
  }

  // Return all mental states defined in the JSON
  List<String> _allMentalStates() {
    if (_cases == null) return [];
    return _cases!
        .map((e) => (e as Map)['mental_state']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // Return all activities for a given mental state
  List<Map<String, String>> _activitiesForState(String state) {
    if (_cases == null) return [];
    for (final s in _cases!) {
      final m = s as Map<String, dynamic>;
      if ((m['mental_state'] ?? '') == state) {
        final acts = (m['activities'] as List)
            .map<Map<String, String>>((a) {
              final mm = a as Map<String, dynamic>;
              return {
                'title': (mm['title'] ?? mm['activity'] ?? '').toString(),
                'category': (mm['category'] ?? '').toString(),
                'description': (mm['description'] ?? '').toString(),
                'time': (mm['time'] ?? mm['duration'] ?? '').toString(),
              };
            })
            .where((x) => x['title']!.isNotEmpty)
            .toList();
        return acts;
      }
    }
    return [];
  }

  // Pick two random activities (preferably from different categories)    --- use another one
  /* List<Map<String, String>> _pickTwo(List<Map<String, String>> all) {
    if (all.isEmpty) return [];

    final byCat = <String, List<Map<String, String>>>{};
    for (final a in all) {
      final c = (a['category'] ?? '').toLowerCase();
      byCat.putIfAbsent(c, () => []).add(a);
    }

    if (byCat.keys.length >= 2) {
      final cats = byCat.keys.toList()..shuffle(_rng);
      final first = byCat[cats[0]]!..shuffle(_rng);
      final second = byCat[cats[1]]!..shuffle(_rng);
      return [first!.first, second!.first];
    }

    final copy = [...all]..shuffle(_rng);
    return copy.take(2).toList();
  } */

  String _activityKey(Map<String, String> a) {
    final cat = (a['category'] ?? '').trim();
    final title = (a['title'] ?? '').trim();
    return '$cat|$title'; // used to identify duplicates
  }

  /// Picks up to 2 new activities for a given state, avoiding repeats in the same session.
  List<Map<String, String>> _pickTwoUnique(
    String state,
    List<Map<String, String>> all,
  ) {
    if (all.isEmpty) return [];

    // 1️ Get or create a used-set for this mental state
    final used = _usedActivitiesByState.putIfAbsent(state, () => <String>{});

    // 2️ Filter out already used activities
    final unseen = all.where((a) => !used.contains(_activityKey(a))).toList();
    if (unseen.isEmpty) return [];

    // 3️ Group unseen by category
    final byCat = <String, List<Map<String, String>>>{};
    for (final a in unseen) {
      final c = (a['category'] ?? '').toLowerCase();
      byCat.putIfAbsent(c, () => []).add(a);
    }

    // 4️ Try to pick two from different categories when possible
    final cats = byCat.keys.toList()..shuffle(_rng);
    final picked = <Map<String, String>>[];

    if (cats.isNotEmpty) {
      byCat[cats[0]]!..shuffle(_rng);
      picked.add(byCat[cats[0]]!.first);
    }
    if (cats.length >= 2) {
      byCat[cats[1]]!..shuffle(_rng);
      picked.add(byCat[cats[1]]!.first);
    }

    // 5️ If there’s only one category, try to pick two from it (if possible)
    if (picked.length < 2 && cats.isNotEmpty) {
      final sameCatPool = byCat[cats[0]]!..shuffle(_rng);
      final next = sameCatPool.firstWhere(
        (a) => _activityKey(a) != _activityKey(picked.first),
        orElse: () => {},
      );
      if (next.isNotEmpty) picked.add(next as Map<String, String>);
    }

    // 6️ Mark selected ones as used
    for (final a in picked) {
      used.add(_activityKey(a));
    }

    return picked;
  }

  // Ask Gemini to classify the user message into one of the mental states
  Future<String?> _classifyState(String contextMessage) async {
    await ensureJsonLoaded();
    final options = _allMentalStates();
    if (options.isEmpty) return null;

    // quick local : greetings / very short messages -> NONE
    final msg = contextMessage.trim().toLowerCase();
    const greetings = [
      'hi',
      'hello',
      'hey',
      'yo',
      'salam',
      'مرحبا',
      'السلام عليكم',
    ];
    if (msg.length < 8 || greetings.contains(msg)) return 'NONE';

    final sys =
        """
You are a careful emotional classifier.
You will analyze the user's message and decide which one mental state (from the list below)
best describes the emotion or need behind the message — even if th

For example:
- "I'm bored" → could mean "Less Motivation"
- "I can't focus" → could mean "Distracted"
- "I feel stressed" → could mean "Anxious"

Choose the single best match from this list:
${options.join(' | ')}

If you are not sure, or the message does not fit any state, return EXACTLY: NONE
if the user ask for help without mention any mental state or some emotion that could related to it , return :NONE 
Do not add any extra words.

otherwise return ONLY the state name , Do not add any extra words.

""";

    String one = "";
    try {
      final resp = await Gemini.instance.text(
        'System:\n$sys\n\nUser:\n$contextMessage',
      );
      print("responce mental state is $resp");
      final raw = resp?.output?.trim() ?? '';
      one = raw.split('\n').first.replaceAll(RegExp(r'^"+|"+$'), '').trim();
    } catch (e) {
      return "Error";
    }
    // Accept "NONE" explicitly
    if (one.toUpperCase() == 'NONE') return 'NONE';

    // Otherwise only accept exact match from options
    final hit = options.firstWhereOrNull(
      (e) => e.toLowerCase() == one.toLowerCase(),
    );
    return hit ?? 'NONE';
  }

  /// Main sendMessage:
  /// - Classifies the user’s message into a mental state
  /// - Selects two activities from JSON for that state
  /// - Stores them in [lastSuggested]
  /// - Returns a warm message for the chatbot UI
  Future<String> sendMessage(String userMessage) async {
    await ensureJsonLoaded();
    lastSuggested = [];
    final displayName = userName ?? "friend";

    final memory = _buildMemory(limit: 4); // remeber the chat before classufing
    final contextMessage = memory.isNotEmpty
        ? 'Previous conversation:\n$memory\n\nUser:\n$userMessage'
        : userMessage;

    // 1) classify first
    final state = await _classifyState(contextMessage);
    if (state == 'Error') {
      return "Sorry, I'm having trouble connecting right now. Please try again in a moment 💫";
    }

    // i move it outside if in order to use it later
    final casualPrompt =
        """
You are Lumra, a personal assistant that supports individuals with ADHD.
You are not a medical professional and must never provide diagnostic or clinical information.
Your role is to offer warm emotional support and simple guidance related only to ADHD, self-care, focus, organization, and emotional well-being.

If the user talks about topics outside ADHD, mental health, or personal improvement, reply politely:
-"I'm sorry, but I’m only your personal assistant and can’t provide help with that."

Engage in natural, friendly conversation. If the user is simply chatting or sharing thoughts that don’t clearly indicate a mental state,
respond normally — be kind, supportive, and keep the flow natural. Do NOT suggest activities here.(if the user want chatting follow him and le the conversation smooth try to let him talk more  )
Keep the reply short and in ENGLISH. The user's name is "$displayName". Use it naturally when appropriate (e.g., greetings or empathy).
""";

    // 2) No clear state -> chat normally using your previous instruction prompt (NO JSON here)
    if (state == 'NONE' || state == null) {
      // must be the same with the others promt (number of remebred masseges)
      final fullPrompt =
          '''
System:
$casualPrompt

${memory.isNotEmpty ? 'Previous Conversation:\n$memory\n' : ''}
User:
$userMessage
''';

      try {
        final resp = await Gemini.instance.text(fullPrompt);
        return resp?.output?.trim() ?? "Got it! How’s your day going?";
      } catch (e) {
        return "Sorry, I'm having trouble connecting right now. Please try again in a moment 💫";
      }
    }

    // 3) Clear state -> fetch strictly from JSON (no gemini suggestions)
    final all = _activitiesForState(state);
    final picked = _pickTwoUnique(state, all);

    print(
      " [Lumra Debug] Detected state = $state, checking if user wants activity...",
    );
    final wantsActivity = await _detectNeedForActivity(
      userMessage,
    ); // Ask Gemini if the user actually wants help or an activity
    print("wants activit? $wantsActivity");
    if (!wantsActivity) {
      // no need to remeber the full conersation
      final memory = _buildMemory(
        limit: 4,
      ); // for jano (here you can control the number of remembred masseges ) -- dont chnage the method only here also in the normal case (no detected mental state must change with this)
      final fullPrompt =
          '''
System:
$casualPrompt

${memory.isNotEmpty ? 'Previous Conversation:\n$memory\n' : ''}
User:
$userMessage
''';

      try {
        final resp = await Gemini.instance.text(fullPrompt);
        return resp?.output?.trim() ??
            "That sounds like it’s been a lot to deal with. I’m here with you.";
      } catch (e) {
        return "Sorry, I'm having trouble connecting right now. Please try again in a moment 💫";
      }
    }
    if (picked.isEmpty) {
      return "I’ve already suggested all the activities for $state. You can view them anytime in the Activities section.";
    }

    // store for saving to Firestore
    lastSuggested = picked;

    //  Prepare text for Gemini — include titles & raw descriptions (for rephrasing)
    final activitiesText = picked
        .map((a) {
          final title = (a['title'] ?? '').trim();
          final desc = (a['description'] ?? '').trim();
          return "- $title${desc.isNotEmpty ? "\n  (description: $desc)" : ""}";
        })
        .join('\n\n---\n\n'); // ← adds clear separation between activities

    //  Gemini prompt — rephrase descriptions & keep spacing
    final systemPrompt =
        """
You are Lumra, a warm and empathetic assistant that supports individuals with ADHD.
The user's name is "$displayName".
Use the name naturally once near the start.
The user's current mental state is: $state

Below are two activities Lumra found in her library.
Each activity includes a short description (inside parentheses).

Your task:
- Rephrase each description smoothly in your own warm and encouraging tone, keeping the same meaning.
- Keep each activity clearly separated from the other with a blank line between them.
- Mention the activity name first, then its rephrased description on the next line.

$activitiesText

Write a friendly 3-part message for the user:
1️ Start with an empathetic, natural sentence that mentions the mental state ($state) — do NOT use quotes.  
   Then, add a short connecting phrase that gently leads into the activities  
   (for example: “Maybe these ideas could bring you a little balance” or “Let’s try a couple of things that might help”).  

2️ Present the two activities one by one, separated clearly with a blank line, each having its short rewritten description.  

3️ End by reminding the user they can find these activities in the Activities section of Lumra.

Keep your tone kind, calm, and human-like.
Avoid quotes, emojis, or bold formatting.
Write in English only.
""";

    try {
      final resp = await Gemini.instance.text('System:\n$systemPrompt');
      return resp?.output?.trim() ??
          "It seems you’re feeling $state. You can check some helpful activities in your Activities section ";
    } catch (e) {
      return "Sorry, I'm having trouble connecting right now. Please try again in a moment 💫";
    }

    // build friendly  reply
    /* final b = StringBuffer();
    b.writeln('I hear you, it seems you might be feeling "$state".');
    b.writeln('Maybe these could help you feel a bit better:');
    for (final a in picked) {
      final cat = a['category'] ?? 'Activity';
      final title = a['title'] ?? '';
      final time = (a['time'] ?? '').isNotEmpty ? ' (${a['time']})' : '';
      b.writeln('– $cat: $title$time');
    }
    b.writeln(
      'Would you like me to suggest more ideas like these, or try one?',
    );

    return b.toString(); */
  }

  Future<bool> _detectNeedForActivity(String userMessage) async {
    // to check if the user ask for help
    final prompt = """
You are analyzing a user's message sent to a self-care assistant.
Decide if the user is *asking for help*, *asking for a solution*, or *wants an activity*.

Instructions:
- You only need to check whether the user is currently asking for help or guidance.
- The user might say general things like "help me", "please help", or "I need something" without specifying what — these still count as asking for help.
- The user might also ask questions that imply a need for guidance (e.g., "what should I do", "how can I fix this").




Return exactly:
- "YES" → if the user clearly wants help, advice, or an activity.
- "NO"  → if the user is just expressing feelings, talking casually, or not asking for help.

Examples:
User: "I feel bored" → NO  
User: "I feel bored, what should I do?" → YES  
User: "I'm tired" → NO  
User: "Can you suggest something to calm me down?" → YES  
User: "Help me focus please" → YES  
User: "I'm just chatting" → NO
User: "Please help" → YES  
User: "Can you help me?" → YES  
User: "I need help" → YES  
""";
    try {
      final resp = await Gemini.instance.text(
        'System:\n$prompt\n\nUser:\n$userMessage',
      );
      print(" [Lumra Debug] Gemini raw response: ${resp?.output}"); // debug
      final output = resp?.output?.trim().toUpperCase() ?? 'NO';
      return output.contains('YES');
    } catch (e) {
      return false;
    }
  }

  ///  Build a short memory for Gemini (recent messages)  to remember the chat
  String _buildMemory({int limit = 4, int maxCharsPerMsg = 160}) {
    if (chatHistory.isEmpty) return '';

    // Since you insert at index 0 (newest first), reverse to oldest → newest.
    final recent = chatHistory.take(limit).toList().reversed;

    final lines = recent.map((m) {
      final role = (m['author'] == 'user') ? 'User' : 'Lumra';
      var text = (m['text'] ?? '').toString().replaceAll('\n', ' ').trim();
      if (text.length > maxCharsPerMsg) {
        text = text.substring(0, maxCharsPerMsg) + '…';
      }
      return '$role: $text';
    }).toList();

    return lines.join('\n');
  }

  void clearSessionData() {
    chatHistory.clear(); // clear the chat messages
    lastSuggested.clear(); // reset last suggested activities
    _usedActivitiesByState.clear(); // reset the per-session activity tracker
    userName = null;
  }
}
