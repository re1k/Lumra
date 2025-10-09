import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:get/get.dart';
import 'package:lumra_project/controller/ChatBoot/AdhdChatBootController.dart';
import "package:lumra_project/theme/base_themes/colors.dart";

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ChatController controller = Get.put(ChatController());

  // list of chat messages for the UI
  final List<types.Message> _messages = [];

  // define your user and Lumra bot
  final _user = const types.User(id: 'user');
  final _bot = const types.User(id: 'lumra');

  // called when user presses "Send"
  Future<void> _handleSend(types.PartialText message) async {
    // Add user's message to the chat
    final userMsg = types.TextMessage(
      id: Random().nextInt(999999).toString(),
      author: _user,
      text: message.text,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    setState(() => _messages.insert(0, userMsg));

    // Optional typing indicator
    final typingMsg = types.TextMessage(
      id: 'typing',
      author: _bot,
      text: '...',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    setState(() => _messages.insert(0, typingMsg));

    // Ask Gemini for a reply
    final replyText = await controller.sendMessage(message.text);

    // Remove typing indicator
    setState(() => _messages.removeWhere((m) => m.id == 'typing'));

    // Add Lumra's reply
    final botMsg = types.TextMessage(
      id: Random().nextInt(999999).toString(),
      author: _bot,
      text: replyText,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    setState(() => _messages.insert(0, botMsg));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Container(
          width: 360,
          height: 520,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 55,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: BColors.secondry,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Lumra Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Chat(
                  messages: _messages,
                  onSendPressed: _handleSend,
                  user: _user,
                  theme: const DefaultChatTheme(
                    backgroundColor: Colors.white,
                    primaryColor: Colors.blueAccent,
                    inputBackgroundColor: Color(0xFFF0F0F0),
                    inputTextStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    sentMessageBodyTextStyle: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                    ),
                    receivedMessageBodyTextStyle: TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
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
