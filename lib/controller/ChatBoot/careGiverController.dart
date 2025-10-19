// lib/controller/chat/caregiver_chat_controller.dart
import 'package:flutter_gemini/flutter_gemini.dart';
import 'baseController.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:lumra_project/controller/auth/auth_controller.dart";

class CaregiverChatController extends BaseChatController {
  String? _userName;

  // ⬇️ Add this helper to remove Markdown
  String _stripMarkdown(String input) {
    var s = input;

    // Bold/italic
    s = s.replaceAll(RegExp(r'(\*\*|__)(.*?)\1'), r'$2');
    s = s.replaceAll(RegExp(r'(\*|_)(.*?)\1'), r'$2');

    // Inline & fenced code (remove backticks, keep content)
    s = s.replaceAll(RegExp(r'`{3}([\s\S]*?)`{3}'), r'$1');
    s = s.replaceAll(RegExp(r'`([^`]*)`'), r'$1');

    // Headings
    s = s.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');

    // Blockquotes
    s = s.replaceAll(RegExp(r'^\s{0,3}>\s?', multiLine: true), '');

    // Links: [text](url) -> text
    s = s.replaceAll(RegExp(r'\[([^\]]+)\]\(([^)]+)\)'), r'$1');

    // Trim repeated spaces/lines
    s = s
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return s.trim();
  }

  void setUserName(String? name) {
    // to get the user name to use it in the chatbot
    _userName = name ?? 'Caregiver';
  }

  void clearChat() {
    chatHistory.clear();
    print(" Chat history cleared on logout");
  }

  String get _sys =>
      """
You are Lumra, a supportive assistant for caregivers of individuals with ADHD.

Your role is to provide calm, practical, and compassionate support. 
You are not a clinician and must never give a diagnosis, medical, or treatment advice.
You are currently chatting with ${_userName ?? 'a caregiver'}.
Address them warmly using their name when appropriate.

You can help caregivers with:
- Understanding and communicating effectively with their loved ones who have ADHD
- Offering emotional support, encouragement, and empathy
- Sharing ideas for organization, structure, and daily routines
- Promoting caregiver self-care, patience, and stress management
- Helping caregivers reframe challenges positively and stay hopeful

If asked for medical or clinical advice, politely respond:
"I'm not a medical professional, but I can help you find calm or suggest ways to support your loved one."

Keep your tone warm, understanding, and empowering — like a gentle friend who truly cares.
Write in clear ENGLISH, with short and supportive responses.
Do not use Markdown, bold, italics, bullet lists, or any formatting.
use only 2 numbers : 
1- 911 for police
2- 977 for emergancy
""";

  @override
  void onInit() {
    super.onInit();

    //  Access the existing AuthController to get the current user
    if (Get.isRegistered<AuthController>()) {
      final authCtrl = Get.find<AuthController>();
      final user = authCtrl.currentUser;

      if (user != null) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).get().then(
          (doc) {
            final name = doc.data()?['firstName'];
            if (name != null && name.toString().trim().isNotEmpty) {
              setUserName(name);
              print("🔹 Loaded caregiver name from Firestore: $name");
            }
          },
        );
      }
    }
  }

  @override
  Future<String> sendMessage(String userMessage) async {
    final memory = buildMemory(limit: 4);
    final prompt =
        '''
System:
$_sys

${memory.isNotEmpty ? 'Previous Conversation:\n$memory\n' : ''}
User:
$userMessage
''';
    try {
      final resp = await Gemini.instance.text(prompt);
      return resp?.output?.trim() ?? "I'm here to help. What’s on your mind?";
    } catch (e) {
      return "Sorry, I'm having trouble connecting right now. Please try again in a moment 💫";
    }
  }
}
