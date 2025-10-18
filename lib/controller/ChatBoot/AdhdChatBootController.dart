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

  void printUsedActivities() {
    if (_usedActivitiesByState.isEmpty) {
      print("🟡 No used activities yet.");
      return;
    }

    print("🧩 Used Activities by Mental State:");
    _usedActivitiesByState.forEach((state, usedSet) {
      print("\n🔹 Mental State: $state");
      for (final activityKey in usedSet) {
        print("   • $activityKey");
      }
    });
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

    /*      put it as a comment (sometimes gimini ignore the activity)
    for (final a in picked) {
      used.add(_activityKey(a));
    } */

    return picked;
  }

  void _markUsed(String state, List<Map<String, String>> shown) {
    final used = _usedActivitiesByState.putIfAbsent(state, () => <String>{});
    for (final a in shown) {
      used.add(_activityKey(a));
    }
  }

  // Ask Gemini to classify the user message into one of the mental states
  Future<String?> _classifyState(String contextMessage) async {
    printUsedActivities();
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
You are an emotional classifier for an ADHD-support assistant.

Your task:
Read the user's message and choose ONE mental state that best describes it.
Sometimes the user will not explicitly mention the mental state, so analyze the context and match it to the closest one if applicable.
In some cases, you will receive a conversation — use the context from previous messages to help you detect the mental state.

If the message does not clearly match any state, return "NONE".

For example:
- "I'm bored" → could mean "Low Motivation"

- "I feel stressed" → could mean "Anxiety"

Choose the single best match from this list only:
${options.join(' | ')}

Your purpose:
- If the user asks for help without mentioning any mental state or emotion, and there are no previous messages (for example: "What can I do?"), return "NONE".
- However, if there are previous messages that show an emotion or mental context, then use the conversation to detect the correct mental state.
- If the message expresses an emotion or mental state but it does not clearly match any item in the list, return "NONE".

If you detect a mental state, return ONLY the exact mental state name from the list.
Do not add any explanations, punctuation, or extra words.

Remember:
- When unsure, do not assume — return "NONE".
- Be consistent and precise in your classification.
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

If the user talks or asks  about topics outside ADHD, mental health, or personal improvement, reply politely:
- "I'm sorry, but I’m only your personal assistant and can’t provide help with that."

Your purpose:

1. If the user is simply chatting or sharing thoughts that don’t clearly indicate a mental state,
   respond naturally — be kind, supportive, and keep the conversation flowing smoothly. 
   Do NOT suggest activities here. If the user wants to chat, follow their lead and keep the conversation relaxed.

2. If the user talks about something that you can give a small piece of advice or simple tips for,
   go ahead and share them (not a full activity — just short, practical suggestions).

3. If the message shows emotions such as sadness, stress, or frustration,
   respond with calm understanding — do NOT amplify the emotion. 
   Stay positive, encouraging, and provide gentle reassurance.

Keep the reply short and in ENGLISH.
The user's name is "$displayName". Use it naturally when appropriate (e.g., greetings or empathy).
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

    final contextMemory = _buildMemory(limit: 4);
    final wantsActivity = await _detectNeedForActivity(
      userMessage,
      contextMessage: contextMemory,
    );

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
- Keep each activity TITLE EXACTLY as it is. Never change, rename, or reword it.
- Only rephrase the DESCRIPTION to make it sound warm and human.
- Keep each activity clearly separated from the other with a blank line between them.
- Always show the original title exactly as provided, then its rephrased description below.

$activitiesText

Write a friendly 3-part message for the user:
1️ Start with an empathetic, natural sentence that mentions the mental state ($state) — do NOT use quotes.  
   Then, add a short connecting phrase that gently leads into the activities  
   (for example: “Maybe these ideas could bring you a little balance” or “Let’s try a couple of things that might help”).  

2️ Present the two activities one by one, separated clearly with a blank line, each having its short rewritten description.  

3️ End by reminding the user they can find these activities in the Activities section of Lumra.

4-  Always reply in a way that feels human, simple, and easy to understan

Keep your tone kind, calm, and human-like.
Avoid quotes, emojis, or bold formatting.
Write in English only.
""";

    try {
      final resp = await Gemini.instance.text('System:\n$systemPrompt');

      final output = resp?.output?.trim() ?? '';

      // Debug Gemini output
      print("🔍 Gemini returned text:\n$output");

      // Find which activity titles appear in Gemini’s message
      final shown = picked.where((a) {
        final cleanTitle = a['title']!
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim()
            .toLowerCase();
        final cleanOutput = output
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim()
            .toLowerCase();
        return cleanOutput.contains(cleanTitle);
      }).toList();
      print("🧩 Titles found:");
      for (final a in shown) {
        print("   ✅ ${a['title']}");
      }

      // Mark as used only what was shown
      _markUsed(state, shown);

      return output.isNotEmpty
          ? output
          : "It seems you’re feeling $state. You can check some helpful activities in your Activities section.";
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

  Future<bool> _detectNeedForActivity(
    String userMessage, {
    String? contextMessage,
  }) async {
    // to check if the user ask for help
    final prompt = """
You are analyzing a user's message sent to a self-care assistant that focuses ONLY on ADHD-related emotional and behavioral support.

Your task:
Decide if the user is *asking for help*, *asking for a solution*, or *wants an activity*, **and** if the message is relevant to ADHD or self-care.

If the user's message is short or unclear (for example: "help", "I need help", "what should I do?"),
you MUST use the previous conversation context to understand what they need help with.


Follow these steps carefully:

1️ Check if the user is asking for help, advice, a suggestion, or an activity.
for Example :
 i need help , what should i do , can you help me 

- If there is no request for help or guidance, 
for Example : 
i fell sressed , i feel bored , today was stressed 
return NO.

2️ If the user is asking for help, check whether the thing they need help with is related to ADHD or self-care topics.
- Relevant topics include: focus, organization, time management, motivation, low energy, procrastination, stress, overthinking, hyperactivity, forgetfulness, frustration, emotions, self-esteem, and relaxation.
- If the help request involves external media, entertainment, or unrelated platforms
  (for example: YouTube, TikTok, movies, social media, music, or any specific app or website),
  you must return NO — even if the message mentions ADHD-related words like "focus" or "time."
  Only return YES if the user is directly asking for advice, guidance, or self-care ideas
  that Lumra itself can provide (not suggestions for external videos, apps, or tools).

 Return YES only if BOTH are satisfied:
- The user is clearly asking for help or a suggestion.
- The help requested is about something relevant to ADHD or self-care.

Otherwise, return NO.

Answer with exactly:
YES
or
NO



""";
    try {
      final memoryPart =
          (contextMessage != null && contextMessage.trim().isNotEmpty)
          ? "Conversation context:\n$contextMessage\n\n"
          : "";

      final fullInput = 'System:\n$prompt\n\n${memoryPart}User:\n$userMessage';

      final resp = await Gemini.instance.text(fullInput);
      print(" [Lumra Debug] Gemini raw response: ${resp?.output}"); // debug

      final raw = resp?.output?.trim() ?? '';
      final norm = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
      return norm == 'YES' || norm == 'TRUE';
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
