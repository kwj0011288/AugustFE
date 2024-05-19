import 'package:http/http.dart' as http;
import 'dart:convert';

// 지원하는 모든 학기 목록을 가져오는 함수
// 지원하는 모든 학기 목록을 가져오는 함수
Future<List<String>> fetchAllSemesters() async {
  final response = await http.get(Uri.parse('http://augustapp.one/semesters/'));

  if (response.statusCode == 200) {
    // Convert the list of int to a list of String
    return List<String>.from(
        jsonDecode(response.body).map((i) => i.toString()));
  } else {
    throw Exception('Failed to load semesters');
  }
}

String getSeasonFromSemester(String semester) {
  if (semester.endsWith("01")) {
    return "Spring";
  } else if (semester.endsWith("05")) {
    return "Summer";
  } else if (semester.endsWith("08")) {
    return "Fall";
  } else if (semester.endsWith("12")) {
    return "Winter";
  } else {
    return "Invalid";
  }
}

String getOriginalSemester(String formattedSemester) {
  // 정규 표현식을 사용하여 계절과 년도를 추출
  RegExp regex = RegExp(r"(\w+) (\d+)");
  Match? match = regex.firstMatch(formattedSemester);

  if (match != null && match.groupCount >= 2) {
    // 계절을 가져옴
    String season = match.group(1)!;

    // 년도를 가져옴
    String year = match.group(2)!;

    // 계절에 따라 월을 매핑
    String month;
    switch (season) {
      case 'Spring':
        month = "01";
        break;
      case 'Summer':
        month = "05";
        break;
      case 'Fall':
        month = "08";
        break;
      case 'Winter':
        month = "12";
        break;
      default:
        throw Exception("Invalid season format");
    }

    // 원래의 학기 형식으로 반환 (예: "2023-01")
    return "$year$month";
  }

  throw Exception("Invalid semester format");
}
