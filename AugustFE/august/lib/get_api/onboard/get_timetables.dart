import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

Future<String?> getTimetableFromServer(int semester) async {
  final prefs = await SharedPreferences.getInstance();
  final accessToken = prefs.getString('accessToken');

  var url = Uri.parse('https://augustapp.one/timetables/$semester/');

  var response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    },
  );

  if (response.statusCode >= 200 && response.statusCode < 300) {
    // 요청이 성공했다면, 응답 본문을 반환
    await saveTimetableToLocalStorage(response.body);
    return response.body;
  } else {
    // 실패한 경우, null을 반환하거나 적절한 예외 처리를 수행
    print('Failed to fetch timetable with status code: ${response.statusCode}');
    return null;
  }
}

Future<void> saveTimetableToLocalStorage(String timetableJson) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('timetableData', timetableJson);
}
