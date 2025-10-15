// lib/controller/chat/base_chat_controller.dart
import 'package:get/get.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:lumra_project/theme/base_themes/api_constants.dart';

abstract class BaseChatController extends GetxController {
  final List<Map<String, dynamic>> chatHistory = [];

  @override
  void onInit() {
    super.onInit();
    Gemini.init(apiKey: APIsConstants.Gimini_API, enableDebugging: true);
  }

  String buildMemory({int limit = 4, int maxCharsPerMsg = 160}) {
    if (chatHistory.isEmpty) return '';
    final recent = chatHistory.take(limit).toList().reversed;
    return recent
        .map((m) {
          final role = (m['author'] == 'user') ? 'User' : 'Lumra';
          var text = (m['text'] ?? '').toString().replaceAll('\n', ' ').trim();
          if (text.length > maxCharsPerMsg)
            text = '${text.substring(0, maxCharsPerMsg)}…';
          return '$role: $text';
        })
        .join('\n');
  }

  Future<String> sendMessage(String userMessage); // each bot implements this
  void clearChat() {
    chatHistory.clear();
    print(" Chat history cleared on logout");
  }
}
