import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';

class BAppBarTheme {
  BAppBarTheme._();

  /// This replaces the old AppBar implementation for consistent styling across the app..
  ///
  /// Usage:
  /// BAppBarTheme.createHeader(
  ///   context: context,
  ///   title: 'Page Title',
  ///   subtitle: 'Page subtitle',
  ///   showBackButton: true, // optional, defaults to false
  ///   onBackPressed: () => Navigator.pop(context), // optional
  ///   actions: [IconButton(...)], // optional
  /// )
  /// ```
  static Widget createHeader({
    required BuildContext context,
    required String title,
    String? subtitle,
    bool showBackButton = false,
    VoidCallback? onBackPressed,
    List<Widget>? actions,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        BSizes.lg,
        MediaQuery.of(context).viewPadding.top + BSizes.lg,
        BSizes.lg,
        BSizes.xs,
      ),
      child: showBackButton
          ? Stack(
              clipBehavior: Clip.none, // we don't want it to be clipped
              children: [
                // Back button positioned at the left
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: onBackPressed ?? () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: BColors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: BColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),

                // Centered title and subtitle
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: BColors.black,
                          fontSize: 28,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: BSizes.xs),
                        Text(
                          subtitle,
                          style: textTheme.bodyLarge?.copyWith(
                            color: BColors.darkGrey,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),

                // Actions positioned at the right (if provided)
                if (actions != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions,
                      ),
                    ),
                  ),
              ],
            )
          : Row(
              children: [
                // Title and subtitle - left aligned when no back button (not used)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: BColors.black,
                          fontSize: 28,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.start,
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: BSizes.xs),
                        Text(
                          subtitle,
                          style: textTheme.bodyLarge?.copyWith(
                            color: BColors.darkGrey,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.start,
                        ),
                      ],
                    ],
                  ),
                ),

                // Actions (if provided)
                if (actions != null) ...[
                  SizedBox(width: BSizes.md),
                  ...actions,
                ],
              ],
            ),
    );
  }

  /// AppBar theme for backward compatibility
  /// This is kept for any remaining AppBar usage that hasn't been migrated yet ....
  static const lightAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: BColors.primary,
    surfaceTintColor: Color.fromARGB(255, 240, 240, 240),
    iconTheme: IconThemeData(
      color: Color.fromARGB(255, 255, 255, 255),
      size: 24,
    ),
    actionsIconTheme: IconThemeData(
      color: Color.fromARGB(255, 255, 255, 255),
      size: 24,
    ),
    titleTextStyle: TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      color: Color.fromARGB(255, 252, 250, 250),
    ),
  );
}
