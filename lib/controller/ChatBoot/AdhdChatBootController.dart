// lib/controller/ChatBoot/AdhdChatBootController.dart
import 'dart:convert';
import 'dart:math';
import 'package:get/get.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:lumra_project/theme/base_themes/api_constants.dart';

class ChatController extends GetxController {
  List<dynamic>? _cases; // JSON data
  final Random _rng = Random();

  /// Stores the last two selected activities from JSON,
  /// each element: {title, category, description, time}
  List<Map<String, String>> lastSuggested = [];

  List<Map<String, dynamic>> chatHistory = [];

  @override
  void onInit() {
    super.onInit();
    Gemini.init(apiKey: APIsConstants.Gimini_API, enableDebugging: true);
    _loadJsonCases();
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

  // Pick two random activities (preferably from different categories) مهمممة
  List<Map<String, String>> _pickTwo(List<Map<String, String>> all) {
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
  }

  // Ask Gemini to classify the user message into one of the mental states
  Future<String?> _classifyState(String userMessage) async {
    await ensureJsonLoaded();
    final options = _allMentalStates();
    if (options.isEmpty) return null;

    // quick local : greetings / very short messages -> NONE
    final msg = userMessage
        .trim()
        .toLowerCase(); // لان البرومت حقك ليان شوي خبص مع الستور ، ف هذا أفضل واذا تحسين حقك أزين جربيه بس بيطلع غريب اللوجيك ترى
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
You are a careful classifier. Choose one mental state from this list:
${options.join(' | ')}

Return ONLY the state name IF the user's message clearly indicates it.
If not clearly indicated, return EXACTLY: NONE
Do not add any extra words.
""";
    // النون هذي مارح تطلع لليوزر بس عشان نستخدمها بالميثود الثانية ويطلع له كلام
    final resp = await Gemini.instance.text(
      'System:\n$sys\n\nUser:\n$userMessage',
    );
    final raw = resp?.output?.trim() ?? '';
    final one = raw.split('\n').first.replaceAll(RegExp(r'^"+|"+$'), '').trim();

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

    // 1) classify first
    final state = await _classifyState(userMessage);

    // 2) No clear state -> chat normally using your previous instruction prompt (NO JSON here)
    if (state == 'NONE' || state == null) {
      // شوفي هنا يشبه حقك بس استخدمنا نون
      const casualPrompt = """
You are Lumra, a personal assistant that supports individuals with ADHD.
You are not a medical professional and must never provide diagnostic or clinical information.
Your role is to offer warm emotional support and simple guidance related only to ADHD, self-care, focus, organization, and emotional well-being.

If the user talks about topics outside ADHD, mental health, or personal improvement, reply politely:
-"I'm sorry, but I’m only your personal assistant and can’t provide help with that."

Engage in natural, friendly conversation. If the user is simply chatting or sharing thoughts that don’t clearly indicate a mental state,
respond normally — be kind, supportive, and keep the flow natural. Do NOT suggest activities here.
Keep the reply short and in ENGLISH.
""";

      final resp = await Gemini.instance.text(
        'System:\n$casualPrompt\n\nUser:\n$userMessage',
      );
      return resp?.output?.trim() ?? "Got it! How’s your day going?";
    }

    // 3) Clear state -> fetch strictly from JSON (no gemini suggestions)
    final all = _activitiesForState(state);
    final picked = _pickTwo(all);
    if (picked.isEmpty) {
      return 'I recognized your state as "$state", but I couldn’t find activities for it.';
    }

    // store for saving to Firestore
    lastSuggested = picked;

    // build friendly  reply
    final b = StringBuffer();
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

    return b.toString();
  }
}
