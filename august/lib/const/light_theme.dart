import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  hoverColor: Colors.transparent,
  fontFamily: 'Apple',
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    background: Color(0xFFffffff), //백그라운드 색 (가장 밝음)
    primaryContainer: Colors.white, // 타임테이블 색 (2번째 밝음)
    primary: Color.fromARGB(255, 225, 224, 224), // 버튼 색  (3번째 밝음)
    secondary: Color.fromARGB(255, 46, 46, 50), // ??? 색 (4번째 밝음)
    secondaryContainer: Color.fromARGB(255, 46, 46, 50), // ??? 색 (5번째 밝음)

    ///////////
    inversePrimary: Colors.grey.shade100,

    ///////////////
    shadow: Colors.grey.shade300,
    outline: Colors.black, // for icons and text

    tertiaryContainer: Colors.grey.shade100, // 로딩 배경
    tertiary: Colors.black.withOpacity(0.04), //로딩 안쪽
  ),
);

//Colors.grey.shade300,

final List<Color> tileColorsLight = [
  Color(0xFFe5fff9),
  Color(0xFFe2fbff),
  Color(0xFFe3ecff),
  Color(0xFFe9e2ff),
  Color(0xFFffefe5),
  Color(0xFFffe6ea),
  Color(0xFFfff7e6),
];

/*

import 'package:august/const/tile_color.dart';
import 'package:flutter/material.dart';

ThemeData dartTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    background: Color(0xFF252525), //백그라운드 색 (가장 어두움_)
    primaryContainer: Color(0xFF333333), // 타임테이블  색(2번째 어두움)
    primary: Color(0xFF4d4d4d), // 버튼 색 (3번째 어두움)
    secondary: Color(0xFF666666), // ??? 색 (4번째 어두움)
    secondaryContainer: Color(0xFF808080), // ??? 색 (5번째 어두움)
    tertiary: Colors.grey.shade800, // ??? 색 (6번째 어두움)
    /////////////////////////
    shadow: Colors.black,
    outline: Colors.white, // for icons and text
    tertiaryContainer: Colors.white.withOpacity(0.04), // for loading
  ),
);

final List<Color> tileColorsDark = [
  Color.fromARGB(255, 192, 215, 209),
  Color.fromARGB(255, 189, 210, 213),
  Color.fromARGB(255, 188, 196, 211),
  Color.fromARGB(255, 180, 174, 197),
  Color.fromARGB(255, 216, 203, 195),
  Color.fromARGB(255, 203, 184, 187),
  Color.fromARGB(255, 200, 194, 181),
];


//Color.fromARGB(255, 44, 44, 47),


*/