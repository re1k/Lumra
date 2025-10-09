import 'dart:convert';
import 'dart:math';
import 'package:get/get.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_gemini/flutter_gemini.dart';
import "package:lumra_project/theme/base_themes/api_constants.dart";

class ChatController extends GetxController {
  List<dynamic>? _cases; // 🟩 Stores the cases and activities from JSON

  @override
  void onInit() {
    super.onInit();

    Gemini.init(apiKey: APIsConstants.Gimini_API, enableDebugging: true);
    print('✅ Gemini initialized successfully');

    _loadJsonCases(); // 🟩 Load your JSON file once when the controller starts
  }

  // 🟩 New method: Load the ADHD cases and activities from JSON file
  Future<void> _loadJsonCases() async {
    try {
      final data = await rootBundle.loadString(
        'assets/adhd_cases/AdhdActivites.json',
      );
      final jsonList = json.decode(data); // ✅ root is a list
      _cases = jsonList; // ✅ assign directly
      print('✅ JSON loaded successfully, found ${_cases!.length} cases.');
    } catch (e) {
      print('❌ Failed to load JSON: $e');
      _cases = null;
    }
  }

  // 🧠 Main sendMessage function
  Future<String> sendMessage(String userMessage) async {
    print('🟢 Step 1: sendMessage() entered');
    try {
      // 🧩 Lumra’s instruction prompt
      final instruction = """
You are Lumra, a personal assistant that supports individuals with ADHD.  
You are not a medical professional and must never provide diagnostic or clinical information.  
Your role is to offer warm emotional support and simple, natural suggestions related only to ADHD, self-care, focus, organization, and emotional well-being.  

If the user talks about topics outside ADHD, mental health, or personal improvement, reply politely:  
"I'm sorry, but I’m only your personal assistant and can’t provide help with that."

If you recognize that the user fits one of the mental states in the attached JSON data,  
start your response with a short, empathetic sentence that shows understanding and care.  
Then, transition smoothly with phrases like  
“maybe these could help you feel a bit lighter ” or “you could try one of these ”.  

Randomly choose two different categories from that mental state,  
and from each category, pick one random activity.  
Present both activities clearly, each on its own line starting with a dash (–).  
Keep your tone soft, human, and encouraging.  

After suggesting the activities, add one short, gentle follow-up question or comment  
that relates naturally to what the user shared or to the activities you suggested.  
Examples include asking how they felt trying it, which idea sounds easier,  
or whether they’d like more help with something similar.  
The question should feel personal, relevant, and caring — not generic.  

If no mental state applies, respond normally with empathy and kindness.







""";

      // 🟩 Include your JSON as context for Gemini
      final contextBlock = _cases != null
          ? """

--- BEGIN CASE DATA ---
${json.encode(_cases)}
--- END CASE DATA ---
"""
          : "";

      // 🧩 Combine everything into the full prompt
      final fullPrompt =
          """
$instruction

User message: $userMessage
$contextBlock
""";

      // ✉️ Send to Gemini
      final response = await Gemini.instance.text(fullPrompt);

      final output = response?.output ?? "No response";
      print('✅ Step 3: Gemini replied: $output');
      return output;
    } catch (e, s) {
      print('❌ Error: $e');
      print('📄 Stack trace: $s');
      return 'Error: $e';
    }
  }
}
