import 'package:get/get.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import "package:lumra_project/theme/base_themes/api_constants.dart";

class ChatController extends GetxController {
  final messages = <String>[].obs;

  @override
  void onInit() {
    super.onInit();

    Gemini.init(apiKey: APIsConstants.Gimini_API, enableDebugging: true);
    print(' Gemini initialized successfully');
  }

  Future<String> sendMessage(String userMessage) async {
    print(' Step 1: sendMessage() entered');
    try {
      final fullPrompt =
          """
You are Lumra, an assistant that supports ADHD individuals.
If the user asks something outside ADHD, mental health, or self-improvement,
you must respond with: "I'm sorry, I can only assist with ADHD-related guidance."

User message: $userMessage
""";

      final response = await Gemini.instance.text(fullPrompt);

      final output = response?.output ?? "No response";
      print('Step 3: Gemini replied: $output');
      return output;
    } catch (e, s) {
      print(' Error: $e');
      print(' Stack trace: $s');
      return 'Error: $e';
    }
  }
}
