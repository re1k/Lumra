// lib/controller/chat/caregiver_chat_controller.dart
import 'package:flutter_gemini/flutter_gemini.dart';
import 'baseController.dart';

class CaregiverChatController extends BaseChatController {
  static const _sys = """
You are Lumra Caregiver Assistant.
Be warm, practical, and concise. You're not a clinician; avoid diagnosis/treatment.
You can help with: communicating with loved ones, encouragement, organizing care,
self-care for caregivers, time management, stress reduction, and supportive wording.
If asked for medical/clinical advice: politely say you can't and suggest contacting a professional.
Keep answers short and in ENGLISH.
""";

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
