// import 'package:august/components/courseprovider.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:lottie/lottie.dart';
// import 'package:provider/provider.dart';
// import '../components/section_list.dart';
// import '../get_api/class.dart';
// import '../get_api/get_api.dart';
// import '../components/class_tile.dart';
// import '../get_api/schedule.dart';
// import 'edit_page.dart';

// class EditSearchPage extends StatefulWidget {
//   final void Function(GroupList) onCourseSelected;
//   final ValueNotifier<List<GroupList>> addedCoursesNotifier;
//   final String? title;
//   EditSearchPage({
//     Key? key,
//     required this.onCourseSelected,
//     required this.addedCoursesNotifier,
//     this.title,
//   }) : super(key: key);
//   @override
//   State<EditSearchPage> createState() => _SearchPageForEditState();
// }

// class InstructorCourse {
//   final GroupList course;
//   final GroupInstructor instructor;
//   InstructorCourse(this.course, this.instructor);
// }

// class _SearchPageForEditState extends State<EditSearchPage>
//     with SingleTickerProviderStateMixin {
//   List<GroupList> _foundCourses = [];
//   late TextEditingController _keywordController;
//   late Future<List<GroupList>>? _coursesFuture = null;
//   late AnimationController _controller;
//   void addToGroup(GroupList classes) {
//     widget.onCourseSelected(classes);
//   }

//   void removeFromGroup(CourseList course) {
//     widget.addedCoursesNotifier.value.remove(course);
//   }

//   Future<List<GroupList>> _runSearch(String enteredKeyword) async {
//     FetchClass _courses = FetchClass();
//     String semester = '202401'; // 원하는 학기를 값으로 설정하세요.
//     String querytype = 'code';

//     List<GroupList> apiData = await _courses.getClassList(
//         querytype: querytype, semester: semester, query: enteredKeyword);

//     if (mounted) {
//       setState(() {
//         _foundCourses = apiData;
//       });
//     }
//     return apiData;
//   }

//   @override
//   void initState() {
//     super.initState();

// // Initialize the keyword controller and add listener
//     this._keywordController = TextEditingController();

// // Initialize animation controller
//     this._controller =
//         AnimationController(duration: Duration(seconds: 2), vsync: this);
//   }

//   @override
//   void dispose() {
//     _keywordController.dispose();
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         appBar: AppBar(
//           elevation: 0,
//           backgroundColor: CupertinoColors.systemBackground,
//           leading: IconButton(
//             onPressed: () {
//               if (Navigator.canPop(context)) {
//                 Navigator.pop(context);
//               }
//             },
//             icon: Icon(
//               Icons.arrow_back_ios,
//               size: 14,
//               color: Colors.black,
//             ),
//           ),
//           centerTitle: false,
//           titleSpacing: 0.0,
//           title: Transform(
// // you can forcefully translate values left side using Transform
//             transform: Matrix4.translationValues(-20.0, 0.0, 0.0),
//             child: Text(
//               "Edit",
//               style: TextStyle(
//                 color: Colors.black,
//               ),
//             ),
//           ),
//         ),
//         body: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: const EdgeInsets.only(left: 20, bottom: 0),
//               child: Text(
//                 'Search',
//                 style: TextStyle(
//                   fontSize: 32,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             Padding(
//                 padding: EdgeInsets.only(
//                     top: 15.0, bottom: 10.0, left: 15.0, right: 15.0),
//                 child: TextField(
//                     autofocus: true,
//                     controller: _keywordController,
//                     decoration: InputDecoration(
//                       contentPadding: EdgeInsets.symmetric(vertical: 15.0),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(width: 0.8),
//                       ),
//                       hintText: 'Search Course',
//                       prefixIcon: Icon(
//                         Icons.search,
//                         size: 30.0,
//                       ),
//                       suffixIcon: IconButton(
//                         onPressed: () {
//                           _keywordController.clear();
//                           setState(() {
//                             _coursesFuture =
//                                 null; // Set to null when the search bar is cleared.
//                             _foundCourses =
//                                 []; // Clear the list of found courses.
//                           });
//                         },
//                         icon: Icon(Icons.clear),
//                       ),
//                     ),
//                     onSubmitted: (String value) async {
//                       setState(() {
//                         _coursesFuture = _runSearch(value.trim());
//                       });
//                     })),
//             Expanded(
//               child: FutureBuilder<List<GroupList>>(
//                 future: _coursesFuture,
//                 builder: (context, snapshot) {
//                   if (_coursesFuture == null) {
//                     return Center(
//                       child: Padding(
//                         padding: const EdgeInsets.only(bottom: 30, left: 20),
//                         child: Text(
//                           'Please enter a Course to search for courses',
//                           style: TextStyle(
//                               fontSize: 20, fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                     );
//                   } else if (snapshot.connectionState ==
//                       ConnectionState.waiting) {
//                     return Center(
//                       child: Text('Loading courses...'),
//                     );
//                   } else if (snapshot.hasError) {
//                     return Text('Error: ${snapshot.error}');
//                   } else if (_foundCourses.isEmpty) {
// // Add this condition.
//                     return Center(
//                         child: Text(
//                             'No courses found. Please try another keyword.'));
//                   } else {
// // Flatten the list of instructors.
//                     // List<GroupInstructor> instructorCourses = [];
//                     // for (var course in _foundCourses) {
//                     //   for (var instructor in course.instructors!) {
//                     //     instructorCourses
//                     //         .add(GroupInstructor(course, instructor));
//                     //   }
//                     // }
//                     return ListView.builder(
//                       itemCount: _foundCourses.length,
//                       itemBuilder: (context, index) {
//                         var course = _foundCourses[index];

//                         // GroupList 객체를 CourseList, 그리고 ScheduleList로 변환
//                         CourseList courseList =
//                             convertGroupListToCourseList(course);
//                         ScheduleList scheduleList =
//                             convertCourseListToScheduleList(courseList);

//                         return Theme(
//                           data: ThemeData()
//                               .copyWith(dividerColor: Colors.transparent),
//                           child: Card(
//                             color: Colors.grey.shade300,
//                             shape: RoundedRectangleBorder(
//                               // side: BorderSide(color: Colors.transparent),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             elevation: 5.0,
//                             margin: EdgeInsets.symmetric(
//                                 horizontal: 10.0, vertical: 6.0),
//                             child: ExpansionTile(
//                               title: Text(course.courseCode!,
//                                   style: TextStyle(fontSize: 18)),
//                               subtitle: Text(
//                                 course.instructors!
//                                     .map((e) => e.name)
//                                     .join(', '),
//                                 style: TextStyle(color: Colors.grey),
//                               ),
//                               tilePadding: EdgeInsets.only(
//                                   left: 20, bottom: 15, top: 15, right: 20),
//                               childrenPadding: EdgeInsets.only(bottom: 15),
//                               backgroundColor: Colors.transparent,
//                               children: <Widget>[
//                                 CourseSections(
//                                   course: scheduleList,
//                                 )
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   }
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // GroupList 객체를 CourseList 객체로 변환하는 함수
// CourseList convertGroupListToCourseList(GroupList group) {
//   return CourseList(
//     name: group.name,
//     courseCode: group.courseCode,
//     credits: group.credits,
//     sections: group.instructors
//         ?.map((instructor) => Section(
//               code: instructor
//                   .name, // `GroupInstructor`에서 `Section`으로 변환하는 방식은 데이터에 따라 조정해야 할 수 있습니다.
//               instructors: [instructor.name!], // 예시로, 강사 이름을 직접 할당합니다.
//               // 나머지 필요한 `Section` 필드는 실제 데이터 구조에 맞춰 조정해야 합니다.
//             ))
//         .toList(),
//   );
// }

// ScheduleList convertCourseListToScheduleList(CourseList course) {
//   // 예시로, 첫 번째 섹션의 정보를 사용하여 ScheduleList 객체를 생성합니다.
//   // 실제 구현에서는 CourseList 구조와 필요에 따라 조정이 필요합니다.
//   Section section = course.sections!.first;
//   return ScheduleList(
//       id: null, // 실제 ID가 필요한 경우 설정해야 합니다.
//       name: course.name,
//       instructors: section.instructors,
//       meetings: section.meetings
//           ?.map((meeting) => ScheduleMeeting(
//               building: meeting.building,
//               room: meeting.room,
//               days: meeting.days,
//               startTime: meeting.startTime,
//               endTime: meeting.endTime))
//           .toList(),
//       courseCode: course.courseCode,
//       sectionCode: section.code,
//       credits: course.credits,
//       seats: section.seats,
//       openSeats: section.openSeats,
//       waitlist: section.waitlist);
// }

// // 이 함수는 ScheduleList 객체를 받아 해당 과목을 타임테이블에 추가하는 로직을 구현해야 합니다.
// void addToGroup(BuildContext context, ScheduleList schedule) {
//   // 예시: ScheduleList 객체를 사용하여 코스를 타임테이블에 추가하는 로직 구현
//   Provider.of<CoursesProvider>(context, listen: false)
//       .addCourseToCurrentTimetable(schedule);

//   // 필요한 추가 로직을 여기에 구현하세요.
// }

// class CourseSections extends StatelessWidget {
//   final ScheduleList course;
//   const CourseSections({
//     Key? key,
//     required this.course,
//   }) : super(key: key);
//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       shrinkWrap: true,
//       physics: NeverScrollableScrollPhysics(),
//       itemCount: course.instructors?.length ?? 0,
//       itemBuilder: (context, index) {
//         var meeting = course.meetings?[index];
//         return Card(
//           color: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           elevation: 4.0,
//           margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
//           child: Padding(
//             padding: const EdgeInsets.only(left: 1, top: 10, bottom: 10),
//             child: ListTile(
//               tileColor: Colors
//                   .transparent, // Change background color of the list tile.
//               title: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     course.sectionCode!,
//                     style: TextStyle(fontSize: 18),
//                   ),
//                   SizedBox(height: 5),
//                 ],
//               ), // Increase font size and change color to grey.
//               subtitle: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('${course.instructors}',
//                       style: TextStyle(color: Colors.grey)),
//                   SizedBox(
//                     height: 5,
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.only(bottom: 3),
//                     child: Text(
//                         '${meeting?.days} ${meeting?.startTime} ~ ${meeting?.endTime}, Room: ${meeting?.building} ${meeting?.room}'),
//                   )
//                 ],
//               ),
//               trailing: IconButton(
//                 icon: Icon(Icons.add),
//                 color: Colors.black, // Change the icon color to blue accent.
//                 onPressed: () {
//                   addToGroup(context, course);
//                   Navigator.pop(context);
//                 },
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
