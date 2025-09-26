import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';

///This controls the appearance of all text input fields (TextFormField)
class BTextFormFieldTheme {
  BTextFormFieldTheme._(); // private constructor

  ///---LIGHT THEME--///
  static InputDecorationTheme lightInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 2,

    /// Limits error messages below the input field ,Prevents overflow or too much vertical space taken by error text
    prefixIconColor: Colors.grey,

    ///LTR icons Color on the text field the ones: Useful when you want to show an icon like email, search, username, etc. at the beginning of the input.
    suffixIconColor: Colors.grey,

    ///RTL icons Color  on the text field the ones: Used often for toggles like "show/hide password", "clear input".
    labelStyle: const TextStyle().copyWith(
      ///the text inside
      fontSize: 14,
      color: Colors.black,
    ),
    hintStyle: const TextStyle().copyWith(
      ///Styles the hint (the faded placeholder text like “Enter your email”).
      fontSize: 14,
      color: Colors.black,
    ),
    errorStyle: const TextStyle().copyWith(
      ///styles the error message making it not italic
      fontStyle: FontStyle.normal,
    ),
    floatingLabelStyle: const TextStyle().copyWith(
      ///the user focuses or types, the label floats up
      color: Colors.black.withOpacity(0.8),
    ),

    border: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: Colors.grey),
    ),
    enabledBorder: const OutlineInputBorder().copyWith(
      ///enabeld but not FOUCESD
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: Colors.grey),
    ),
    focusedBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: Colors.black12),
    ),
    errorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        width: 1,
        color: Color.fromARGB(255, 190, 72, 72),
      ),
    ),
    focusedErrorBorder: const OutlineInputBorder().copyWith(
      /// focused and invalid (error state
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        width: 2,
        color: Color.fromARGB(255, 166, 108, 67),
      ),
    ),
  );
}
