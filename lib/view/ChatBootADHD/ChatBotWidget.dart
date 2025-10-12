import 'package:flutter/material.dart';
import "package:lumra_project/view/ChatBootADHD/ChatBootADHD.dart";
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/controller/ChatBoot/AdhdChatBootController.dart';
import 'package:get/get.dart';

class ChatBotWidget extends StatefulWidget {
  const ChatBotWidget({super.key});

  @override
  State<ChatBotWidget> createState() => _ChatBotWidgetState();
}

class _ChatBotWidgetState extends State<ChatBotWidget> {
  bool _isChatOpen = false;
  final ChatController _chatController = Get.put(
    ChatController(),
    permanent: true,
  );
  final ChatView _chatView = const ChatView(); // TRY TO SAVE THE HISTORY

  /* void _toggleChat() {
    setState(() {
      _isChatOpen = !_isChatOpen;
    });
  } */

  void _toggleChat() async {
    if (_isChatOpen) {
      Navigator.of(context).pop();
      setState(() => _isChatOpen = false);
    } else {
      setState(() => _isChatOpen = true);

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withOpacity(0.15), // dim background
        builder: (BuildContext context) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20, right: 20, left: 20),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(20),
                color: Colors.transparent,
                child: Container(
                  width: 340,
                  height: 480,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: BColors.primary.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    //  persistent chat instance
                    child: _chatView,
                  ),
                ),
              ),
            ),
          );
        },
      );

      setState(() => _isChatOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Floating chat icon
        Positioned(
          bottom: 0, // was 20 changes by layan
          right: 20,
          child: FloatingActionButton(
            backgroundColor: BColors.primary, //  teal color
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            onPressed: _toggleChat,
            child: Icon(
              _isChatOpen ? Icons.close_rounded : Icons.chat_bubble_rounded,
              size: 26,
              color: Colors.white,
            ),
          ),
        ),

        /* // Chat popup
        Positioned(
          bottom: 90,
          right: 20,
          child: Visibility(
            visible: _isChatOpen,
            maintainState: true,
            maintainAnimation: true,
            maintainSize: true,
            child: Material(
              elevation: 10,
              borderRadius: BorderRadius.circular(20),
              color: Colors.transparent,
              child: Container(
                width: 340,
                height: 480,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: BColors.primary.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: const ChatView(),
                ),
              ),
            ),
          ),
        ), */
      ],
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 20);
    path.quadraticBezierTo(size.width / 2, -20, size.width, 20);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0);
    path.quadraticBezierTo(size.width / 2, 10, size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
