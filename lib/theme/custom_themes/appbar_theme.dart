import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';


class BAppBarTheme {
  BAppBarTheme._();

  static const lightAppBarTheme = AppBarTheme(
    elevation: 0, ///Removes the shadow under the `AppBar`
    centerTitle: false, ///makes the text from LTR
    scrolledUnderElevation: 0, ///no shadow when scrolling
    backgroundColor: BColors.primary,
    surfaceTintColor: Color.fromARGB(255, 240, 240, 240),
    iconTheme: IconThemeData(color: Color.fromARGB(255, 255, 255, 255), size: 24), ///styling icons on  the appbar
    actionsIconTheme: IconThemeData(color: Color.fromARGB(255, 255, 255, 255), size: 24), ///the search,filter,notify,share icons
    titleTextStyle: TextStyle(
      fontSize:
      //call the font folder
      18.0,
      fontWeight: FontWeight.w600 ,
      color: Color.fromARGB(255, 252, 250, 250),
    ),

  );

}