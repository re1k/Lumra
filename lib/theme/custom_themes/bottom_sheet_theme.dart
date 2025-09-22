import 'package:flutter/material.dart';

///Bottom Sheets are a versatile UI pattern used to display contextual information or actions by sliding up from the bottom, enhancing user experience by providing quick, accessible options without leaving the current screen.

class BBottomSheetTheme {
  BBottomSheetTheme._();

  static BottomSheetThemeData lightBottomSheetTheme = BottomSheetThemeData(
    showDragHandle: true, ///Enables a small drag handle at the top of the bottom sheet, letting users know it can be swiped down or dragged
    dragHandleColor: Colors.grey,///Enables a small drag handle at the top of the bottom sheet, letting users know it can be swiped down or dragged
    ///specifying its background if used normal or modal
    backgroundColor: Colors.white,
    modalBackgroundColor: Colors.white,

    constraints: const BoxConstraints(minWidth: double.infinity), ///Forces the bottom sheet to take the full width of the screen
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ); // BottomSheetThemeData


}

