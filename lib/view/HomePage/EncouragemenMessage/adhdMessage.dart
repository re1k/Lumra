import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/Homepage/Message/adhd_message_controller.dart';

class EncouragementMessage extends StatelessWidget {
  final String text;
  const EncouragementMessage({
    super.key,
    this.text = 'Remember, one step is still progress!',
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final msgCtrl = Get.put(AdhdMessageController());

    return Obx(() {
      if (!msgCtrl.hasMessage.value) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(BSizes.lg),
          decoration: BoxDecoration(
            color: BColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: BColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: BColors.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: BSizes.md),
              Expanded(
                child: Text(
                  text,
                  style: tt.bodyMedium?.copyWith(
                    color: BColors.black,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              ),
            ],
          ),
        );
      }

      return GestureDetector(
        onTap: () async {
          msgCtrl.toggleOpened();

          if (!msgCtrl.isOpened.value) return;
          await msgCtrl.markOpened();
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: msgCtrl.isOpened.value
              ? Container(
                  key: const ValueKey('opened'),
                  width: double.infinity,
                  height: 110,
                  padding: EdgeInsets.all(BSizes.lg),
                  decoration: BoxDecoration(
                    color: BColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      msgCtrl.messageText.value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: BColors.primary,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'K2D',
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ),
                )
              : Stack(
                  key: const ValueKey('closed'),
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 110,
                      padding: EdgeInsets.all(BSizes.lg),
                      decoration: BoxDecoration(
                        color: BColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: BColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.mail_outline,
                              color: BColors.primary,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: BSizes.md),
                          const Expanded(
                            child: Text(
                              "Message from your caregiver",
                              style: TextStyle(
                                color: BColors.black,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'K2D',
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (msgCtrl.isNewMessage.value)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: BColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "NEW",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      );
    });
  }
}
