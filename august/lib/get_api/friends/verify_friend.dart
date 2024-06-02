import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VerifyFriend {
  final int id;
  final String name;

  VerifyFriend({required this.id, required this.name});

  factory VerifyFriend.fromJson(Map<String, dynamic> json) {
    return VerifyFriend(
      id: json['id'],
      name: json['name'],
    );
  }
}

class VerifyFriendService {
  Future<VerifyFriend?> acceptFriendRequest(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    if (accessToken == null) {
      print('Access token not found');
      return null;
    }

    final url = Uri.parse('http://augustapp.one/friends/accept?code=$code/');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return VerifyFriend.fromJson(data['user']);
    } else {
      String errorMessage;
      if (response.statusCode == 401) {
        errorMessage = 'Authentication credentials were not provided.';
      } else if (response.statusCode == 404) {
        errorMessage = 'Invalid or expired code provided.';
      } else {
        errorMessage =
            'Failed to process the request. Status Code: ${response.statusCode}';
      }
      print(errorMessage);
      return null;
    }
  }
}
