import 'package:http/http.dart' as http;
import 'dart:convert';

Future<List<dynamic>> fetchSections(
    String semester, String queryType, String query) async {
  final response = await http.get(Uri.parse(
      'https://augustapp.one/sections?semester=$semester&querytype=$queryType&query=$query'));

  if (response.statusCode == 200) {
    // 서버가 성공적으로 응답하면, JSON 파싱
    return jsonDecode(response.body);
  } else {
    // 서버가 에러 응답이면 예외 발생시킴.
    throw Exception('Failed to load sections');
  }
}
