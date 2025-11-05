import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/Homepage/Message/caregiver_message_controller.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';

class RealStickerEnvelope extends StatefulWidget {
  const RealStickerEnvelope({super.key});

  @override
  State<RealStickerEnvelope> createState() => _RealStickerEnvelopeState();
}

class _RealStickerEnvelopeState extends State<RealStickerEnvelope> {
  @override
  void initState() {
    super.initState();

    final currentUserId = Get.find<AuthController>().currentUser?.uid;

    if (Get.isRegistered<CaregiverMessageController>()) {
      final existingController = Get.find<CaregiverMessageController>();
      final lastUserId = existingController.auth.currentUser?.uid;

      if (lastUserId != currentUserId) {
        Get.delete<CaregiverMessageController>();
      }
    }

    if (!Get.isRegistered<CaregiverMessageController>()) {
      _msgController = Get.put(CaregiverMessageController());
    } else {
      _msgController = Get.find<CaregiverMessageController>();
    }

    _initFuture = _msgController.checkMessageStatus();
  }

  late final CaregiverMessageController _msgController;
  late final Future<void> _initFuture;
  final TextEditingController _controller = TextEditingController();

  static const int maxMessageLength = 65;
  bool _isOpen = false;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || text.length > maxMessageLength) return;
    await _msgController.sendMessage(text);
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final canSend = _msgController.canSendMessage.value;
      final message = _msgController.lastMessage;

      if (canSend || message == null) {
        return _buildReadyEnvelope();
      } else {
        return _buildEnvelope(message.text);
      }
    });
  }

  Widget _buildInputCard() {
    final text = _controller.text.trim();
    final length = text.length;
    final isActive = text.isNotEmpty && length <= maxMessageLength;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(BSizes.md),
      decoration: BoxDecoration(
        color: BColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isOpen = false;
                  });
                },
                child: Transform.translate(
                  offset: const Offset(0, -9),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: BColors.darkGrey,
                    size: 14,
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontFamily: 'K2D',
                    color: BColors.texBlack,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    hintText: "A word from you can brighten their day ☀️",
                    hintStyle: TextStyle(
                      color: BColors.darkGrey,
                      fontFamily: 'K2D',
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  minLines: 1,
                  maxLength: maxMessageLength,
                  buildCounter:
                      (
                        context, {
                        required currentLength,
                        required isFocused,
                        required maxLength,
                      }) {
                        return Text(
                          "${currentLength ?? 0} / ${maxLength ?? 0}",
                          style: TextStyle(
                            fontFamily: 'K2D',
                            fontSize: 11,
                            color: (currentLength ?? 0) >= (maxLength ?? 0)
                                ? BColors.error
                                : BColors.darkGrey,
                          ),
                        );
                      },
                ),
              ),
              IconButton(
                alignment: Alignment.center,
                icon: Icon(
                  Icons.send_rounded,
                  color: isActive
                      ? BColors.buttonPrimary
                      : BColors.buttonDisabled,
                ),
                onPressed: isActive ? _sendMessage : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnvelope(String message) {
    return GestureDetector(
      onTap: () => setState(() => _isOpen = !_isOpen),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: !_isOpen
            ? _buildClosedEnvelope()
            : _buildOpenedEnvelope(message),
      ),
    );
  }

  Widget _buildReadyEnvelope() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isOpen = true;
        });
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: !_isOpen
            ? Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: 110,
                    decoration: BoxDecoration(
                      color: BColors.secondry, // same envelope color
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      size: const Size(double.infinity, 110),
                      painter: EnvelopeFlapPainter(),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    child: Transform.rotate(
                      angle: -0.06,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white.withOpacity(0.9),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 3,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          "Make your impact ...",
                          style: TextStyle(
                            color: BColors.textprimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'K2D',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 8,
                    right: 12,
                    child: Icon(
                      Icons.edit_note_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              )
            : _buildInputCard(),
      ),
    );
  }

  Widget _buildClosedEnvelope() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: double.infinity,
          height: 110,
          decoration: BoxDecoration(
            color: BColors.secondry,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CustomPaint(
            size: const Size(double.infinity, 110),
            painter: EnvelopeFlapPainter(),
          ),
        ),
        Positioned(
          top: 40,
          child: Transform.rotate(
            angle: -0.06,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: const Text(
                "With care ❤️ Delivered",
                style: TextStyle(
                  color: BColors.textprimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'K2D',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOpenedEnvelope(String message) {
    return Container(
      width: double.infinity,
      height: 110,
      decoration: BoxDecoration(
        color: BColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Message Sent",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: BColors.textprimary,
              fontFamily: 'K2D',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: BSizes.md),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: BColors.primary,
                fontStyle: FontStyle.italic,
                fontSize: 15,
                fontFamily: 'K2D',
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Tap to close",
            style: TextStyle(
              color: BColors.darkGrey,
              fontSize: 11,
              fontFamily: 'K2D',
            ),
          ),
        ],
      ),
    );
  }
}

class EnvelopeFlapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height / 2)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
