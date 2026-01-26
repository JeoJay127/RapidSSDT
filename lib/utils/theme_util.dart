//  theme_util.dart 
//  Created by JeoJay127 
//
import 'package:flutter/material.dart';

class ThemeUtil {
  static ThemeData appTheme({bool isDarkMode = false, Color? primary}) {
    primary ??= isDarkMode ? Colors.blueGrey : Colors.blue;
    return ThemeData(
      useMaterial3: false,
      fontFamily: 'Microsoft YaHei',
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      primaryColor: primary,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: isDarkMode ? Colors.transparent : Colors.grey[850],
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(fontSize: 12, overflow: TextOverflow.visible),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        contentTextStyle: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
