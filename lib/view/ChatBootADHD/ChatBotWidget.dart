import 'package:flutter/material.dart';
import "package:lumra_project/view/ChatBootADHD/ChatBootADHD.dart";
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:get/get.dart';

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
  }

  void _toggleChat() async {
    if (_isChatOpen) {
      Navigator.of(context).pop();
      setState(() => _isChatOpen = false);
      return;
    }

    setState(() => _isChatOpen = true);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true, // keep this
      enableDrag: true, // swipe down still works
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.15),
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

            // 2) YOUR SHEET (on top)
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
        Positioned(
          bottom: 0,
          right: 23,
          child: SizedBox(
            width: 50,
            height: 50,
            child: FloatingActionButton(
              backgroundColor: BColors.primary,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              onPressed: _toggleChat,
              child: Icon(
                _isChatOpen ? Icons.close_rounded : Icons.chat_bubble_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
