import 'package:flutter/material.dart';

class AppFonts {
  static const kalpurush = 'Kalpurush';

  static TextStyle bangla({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double height = 1.45,
  }) {
    return TextStyle(
      fontFamily: kalpurush,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }
}
