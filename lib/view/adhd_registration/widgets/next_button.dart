import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';

class NextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool enabled;

  const NextButton({
    super.key,
    this.onPressed,
    this.text = 'Next',
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 60,
      right: 24,
      child: SizedBox(
        width: 200,
        child: ElevatedButton(
          onPressed: enabled
              ? onPressed
              : null, // Use null when disabled to match QuestionScreen pattern
          style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
            backgroundColor: enabled
                ? WidgetStateProperty.all(BColors.primary)
                : WidgetStateProperty.all(
                    Colors.grey.shade400,
                  ), // Gray background when disabled
            foregroundColor: enabled
                ? WidgetStateProperty.all(BColors.white)
                : WidgetStateProperty.all(
                    BColors.white,
                  ), // White text when disabled
            side: enabled
                ? WidgetStateProperty.all(BorderSide.none)
                : WidgetStateProperty.all(
                    BorderSide(color: Colors.grey.shade400, width: 1),
                  ), // Gray border when disabled
          ),
          child: Text(
            text,
            style:
                const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: BColors.white,
                  fontFamily: 'K2D',
                ).copyWith(
                  color: enabled
                      ? BColors.white
                      : BColors.white, // Always white text for visibility
                ),
          ),
        ),
      ),
    );
  }
}
