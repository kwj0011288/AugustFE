import 'package:august/get_api/onboard/get_semester.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SemesterProvider with ChangeNotifier {
  List<String> _semesterList = [];
  String _semester = '';

  List<String> get semestersList => _semesterList;
  String get semester => _semester;

  SemesterProvider() {
    loadSemesters();
  }

  set semestersList(List<String> value) {
    _semesterList = value;
    if (_semesterList.isNotEmpty) {
      _semester = _semesterList.last;
      saveSemester(_semester);
    }
    notifyListeners();
  }

  set semester(String value) {
    _semester = value;
    saveSemester(value);
    notifyListeners();
  }

  Future<void> loadSemesters() async {
    _semesterList = await fetchAllSemesters();
    if (_semesterList.isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedSemester = prefs.getString('semester');
      _semester = savedSemester ?? _semesterList.last;
    }
    notifyListeners();
  }

  Future<void> saveSemester(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('semester', value);
  }
}
