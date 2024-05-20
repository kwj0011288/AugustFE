// import 'dart:convert';
// import 'package:august/components/timetable.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class TimetableStorage {
//   // Key to use for storing timetable data in SharedPreferences
//   static const String _timetableKey = 'timetable';

//   // Saves the list of timetables to local storage
//   static Future<void> saveTimetableToLocalStorage(
//       List<TimeTables> timetableCollection) async {
//     try {
//       // Convert timetable data into a JSON string
//       String jsonString = jsonEncode(
//           timetableCollection.map((timeTable) => timeTable.toJson()).toList());

//       // Get instance of SharedPreferences and save the JSON string
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       await prefs.setString(_timetableKey, jsonString);

//       print("Timetable data saved successfully.");
//     } catch (e) {
//       print("Failed to save timetable data: $e");
//     }
//   }

//   // Loads the list of timetables from local storage
//   static Future<List<TimeTables>> loadTimetableFromLocalStorage() async {
//     try {
//       // Get instance of SharedPreferences
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? jsonString = prefs.getString(_timetableKey);

//       if (jsonString != null) {
//         // Decode the JSON string back into a list of TimeTables
//         List<dynamic> jsonData = jsonDecode(jsonString);
//         List<TimeTables> timetableCollection =
//             jsonData.map((data) => TimeTables.fromJson(data)).toList();

//         print("Timetable data loaded successfully.");
//         return timetableCollection;
//       } else {
//         print("No timetable data found.");
//         return [];
//       }
//     } catch (e) {
//       print("Failed to load timetable data: $e");
//       return [];
//     }
//   }

//   // Method to clear all saved timetable data
//   static Future<void> clearTimetableData() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_timetableKey);
//     print("Timetable data cleared.");
//   }
// }
