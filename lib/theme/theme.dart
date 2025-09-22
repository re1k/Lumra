import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/custom_themes/appbar_theme.dart';
import 'package:lumra_project/theme/custom_themes/bottom_sheet_theme.dart';
import 'package:lumra_project/theme/custom_themes/checkbox_theme.dart';

import 'package:lumra_project/theme/custom_themes/elevated_button_theme.dart';
import 'package:lumra_project/theme/custom_themes/outlined_button_theme.dart';
import 'package:lumra_project/theme/custom_themes/text_field_theme.dart';
import 'package:lumra_project/theme/custom_themes/text_theme.dart';

class LumraAppTheme {
  //private constructor can not be called, Call the functions
  LumraAppTheme._();

  //can be called as an attribute
  static ThemeData lightTheme = ThemeData (
    useMaterial3: true,
    fontFamily: 'K2D',
    //this is important for flutter to know which theme u on
    brightness:Brightness.light,
    //from constants where the pallet of the app is
    primaryColor: BColors.primary,
    //this gives a uniform background for the app
    scaffoldBackgroundColor: Colors.white ,
    textTheme: BTextTheme.lightTextTheme,
    elevatedButtonTheme: BElevatedButtonTheme.lightElevatedButtonTheme,
    appBarTheme: BAppBarTheme.lightAppBarTheme,
    bottomSheetTheme: BBottomSheetTheme.lightBottomSheetTheme,
    checkboxTheme: BCheckboxTheme.lightCheckBoxTheme,

    outlinedButtonTheme: BOutlinedButtonTheme.lightOutlinedButtonTheme,
    inputDecorationTheme: BTextFormFieldTheme.lightInputDecorationTheme,
      );
}
