import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isFullWidth;
  final bool enabled;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.isFullWidth = true,
    this.enabled = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: (enabled && !isLoading) ? onPressed : null,
        style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
          backgroundColor: (enabled && !isLoading)
              ? WidgetStateProperty.all(BColors.primary)
              : WidgetStateProperty.all(Colors.grey.shade400),
          foregroundColor: (enabled && !isLoading)
              ? WidgetStateProperty.all(BColors.white)
              : WidgetStateProperty.all(BColors.white),
          side: (enabled && !isLoading)
              ? WidgetStateProperty.all(BorderSide.none)
              : WidgetStateProperty.all(
                  BorderSide(color: Colors.grey.shade400, width: 1),
                ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Keep the same layout size by always laying out the text
            Opacity(
              opacity: isLoading ? 0 : 1,
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: BColors.white,
                  fontFamily: 'K2D',
                ).copyWith(color: enabled ? BColors.white : BColors.white),
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
