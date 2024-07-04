import 'package:http/http.dart' as http;
import 'dart:convert';

// 지원하는 모든 학기 목록을 가져오는 함수
// 지원하는 모든 학기 목록을 가져오는 함수
Future<List<String>> fetchAllSemesters() async {
  final response =
      await http.get(Uri.parse('https://augustapp.one/semesters/'));

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
  // Check if the input is already in the desired "yearmonth" format (e.g., "202301")
  RegExp numRegex = RegExp(r'^\d{6}$');
  if (numRegex.hasMatch(formattedSemester)) {
    return formattedSemester; // Return as is if already in the correct format
  }

  // Use regular expression to extract season and year from the formatted string
  RegExp regex = RegExp(r"(\w+) (\d+)");
  Match? match = regex.firstMatch(formattedSemester);

  if (match != null && match.groupCount >= 2) {
    // Extract season and year
    String season = match.group(1)!;
    String year = match.group(2)!;

    // Map season to month
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

    // Return the original semester format (e.g., "202301")
    return "$year$month";
  }

  throw Exception("Invalid semester format");
}
