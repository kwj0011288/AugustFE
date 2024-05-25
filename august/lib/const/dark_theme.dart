import 'package:august/const/tile_color.dart';
import 'package:flutter/material.dart';

ThemeData dartTheme = ThemeData(
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  hoverColor: Colors.transparent,
  fontFamily: 'Apple',
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    background: Color.fromRGBO(37, 37, 37, 1), //백그라운드 색 (가장 어두움_)
    primaryContainer: Color(0xFF333333), // 타임테이블  색(2번째 어두움)
    primary: Color(0xFF4d4d4d), // 버튼 색 (3번째 어두움)
    secondary: Color(0xFF666666), // ??? 색 (4번째 어두움)
    secondaryContainer: Color(0xFF808080), // ??? 색 (5번째 어두움)

    ///////////
    inversePrimary: Color(0xFF666666),
    surfaceTint: Color(0xFF333333), // 타임테이블  색(2번째 어두움)
    /////////////////////////
    shadow: Colors.transparent,
    outline: Colors.white, // for icons and text

    tertiaryContainer: Colors.grey.shade900, // 로딩 배경
    tertiary: Colors.black.withOpacity(0.3), //로딩 안쪽

    onSecondary: Color(0xFF4d4d4d),
  ),
);

final List<Color> tileColorsDark = [
  Color.fromARGB(255, 209, 234, 227),
  Color.fromARGB(255, 185, 221, 227),
  Color.fromARGB(255, 188, 196, 211),
  Color.fromARGB(255, 180, 174, 197),
  Color.fromARGB(255, 216, 203, 195),
  Color.fromARGB(255, 203, 184, 187),
  Color.fromARGB(255, 200, 194, 181),
];
final List<Color> generateDark = [
  Color.fromARGB(255, 209, 234, 227),
  Color.fromARGB(255, 185, 221, 227),
  Color.fromARGB(255, 188, 196, 211),
  Color.fromARGB(255, 180, 174, 197),
  Color.fromARGB(255, 216, 203, 195),
  Color.fromARGB(255, 203, 184, 187),
  Color.fromARGB(255, 200, 194, 181),
];

//Color.fromARGB(255, 44, 44, 47),

