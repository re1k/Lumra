import 'package:flutter/material.dart';
import "package:lumra_project/view/ChatBootADHD/ChatBootADHD.dart";
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:get/get.dart';
import 'dart:async';

// controllers
import 'package:lumra_project/controller/ChatBoot/baseController.dart';
import 'package:lumra_project/controller/ChatBoot/AdhdChatBootController.dart';
import 'package:lumra_project/controller/ChatBoot/careGiverController.dart';

class ChatBotWidget extends StatefulWidget {
  final String role; // 'adhd' or 'caregiver'
  const ChatBotWidget({super.key, required this.role});

  @override
  State<ChatBotWidget> createState() => _ChatBotWidgetState();
}

class _ChatBotWidgetState extends State<ChatBotWidget> {
  bool _isChatOpen = false;
  bool _showHint = false; // start hidden
  Timer? _hintTimer;
  late final AdhdChatController adhdCtrl;
  late final CaregiverChatController cgCtrl;

  // choose controller based on role
  BaseChatController get _activeCtrl =>
      widget.role == 'caregiver' ? cgCtrl : adhdCtrl;

  @override
  void initState() {
    super.initState();

    // register once
    adhdCtrl = Get.put(AdhdChatController(), permanent: true);
    cgCtrl = Get.put(CaregiverChatController(), permanent: true);
    // Show after first frame, then auto-hide after 5s
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _showHint = true);
      _hintTimer = Timer(const Duration(seconds: 7), () {
        ////////////////HERE WE HANDLE THE SECONDS OF THE 💬
        if (mounted) setState(() => _showHint = false);
      });
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _toggleChat() async {
    if (_isChatOpen) {
      Navigator.of(context).pop();
      setState(() => _isChatOpen = false);
      return;
    }

    // Opening
    setState(() {
      _isChatOpen = true;
      _showHint = false; // hide now
    });
    _hintTimer?.cancel(); // stop any pending auto-hide

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true, // keep this
      enableDrag: true, // swipe down still works
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        return Stack(
          children: [
            // 1) FULLSCREEN TAP-TO-DISMISS LAYER (behind the sheet)
            Positioned.fill(
              child: GestureDetector(
                behavior:
                    HitTestBehavior.opaque, // make the whole area tappable
                onTap: () => Navigator.of(ctx).pop(),
                child: const SizedBox.shrink(),
              ),
            ),

            // 2)  SHEET (on top)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20, right: 20, left: 20),
                child: Material(
                  elevation: 10,
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.transparent,
                  child: Container(
                    width: 340,
                    height: 620, //  height (AVOID OVERLAP)
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
                      child: ChatView(controller: _activeCtrl),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (mounted) setState(() => _isChatOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Hint bubble (auto-fades after 5s, doesn't block taps when hidden)
        Positioned(
          bottom: 170,
          right: 35,
          child: AnimatedOpacity(
            opacity: (_showHint && !_isChatOpen) ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            child: IgnorePointer(
              ignoring: !_showHint || _isChatOpen,
              child: ChatHintBubble(
                message: widget.role == 'caregiver'
                    ? "💬 Need to talk? Chat with Lumra!"
                    : "👋 Need a new activity? Chat with Lumra!",
              ),
            ),
          ),
        ),

        // 💬 Chat button
        Positioned(
          bottom: 110,
          right: 23,
          child: Container(
            decoration: BoxDecoration(
              color: BColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              tooltip: _isChatOpen ? 'Close chat' : 'Open chat',
              icon: Icon(
                _isChatOpen ? Icons.close_rounded : Icons.chat_bubble_rounded,
                color: BColors.primary,
                size: 24,
              ),
              onPressed: _toggleChat,
            ),
          ),
        ),
      ],
    );
  }
}

class ChatHintBubble extends StatelessWidget {
  final String message;
  const ChatHintBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
