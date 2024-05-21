import 'dart:convert';

import 'package:animated_hint_textfield/animated_hint_textfield.dart';
import 'package:august/components/courseprovider.dart';
import 'package:august/components/simple_course_tile.dart';
import 'package:august/const/dark_theme.dart';
import 'package:august/const/light_theme.dart';
import 'package:august/get_api/get_semester.dart';
import 'package:august/onboard/semester.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../components/loading.dart';
import '../get_api/class.dart';
import 'package:provider/provider.dart';
import '../get_api/get_api.dart';
import '../get_api/schedule.dart';
import 'package:intl/intl.dart';
import "package:flutter_feather_icons/flutter_feather_icons.dart";
import 'package:shared_preferences/shared_preferences.dart';

class EditSearchPage extends StatefulWidget {
  final ValueNotifier<List<ScheduleList>> addedCoursesNotifier;
  final Function(ScheduleList) onCourseSelected;
  final String? title;
  final int? index;
  final String semester;
  EditSearchPage({
    Key? key,
    required this.addedCoursesNotifier,
    this.title,
    this.index,
    required this.semester,
    required this.onCourseSelected,
  }) : super(key: key);

  @override
  State<EditSearchPage> createState() => _EditSearchPageState();
}

class InstructorCourse {
  final CourseList course;
  final Section section;
  final Meeting meeting;

  InstructorCourse(this.course, this.meeting, this.section);
}

class _EditSearchPageState extends State<EditSearchPage>
    with SingleTickerProviderStateMixin {
  List<CourseList> _foundCourses = [];
  List<String> _searchKeywords = [];
  late TextEditingController _keywordController;
  late Future<List<CourseList>>? _coursesFuture = null;
  late AnimationController _controller;
  String? currentSemester;

  void removeFromGroup(CourseList course) {
    widget.addedCoursesNotifier.value.remove(course);
  }

  // EditSearchPage 클래스 내부

  void _handleCourseSelection(CourseList course) {
    // Convert the selected course to a ScheduleList object
    ScheduleList newSchedule = convertCourseListToScheduleList(course);

    // Print the details of the selected course
    print("Selected course details: ${jsonEncode(newSchedule.toJson())}");

    // Check if the course is already added, if not, add it
    var currentCourses = widget.addedCoursesNotifier.value;
    if (!currentCourses.contains(newSchedule)) {
      currentCourses.add(newSchedule);
      widget.addedCoursesNotifier.value =
          List.from(currentCourses); // Update with the new list
      widget.addedCoursesNotifier
          .notifyListeners(); // Notify listeners of the change
    }
    Provider.of<CoursesProvider>(context, listen: false)
        .addCourseToCurrentTimetableforEditPage(newSchedule);

    widget.onCourseSelected(newSchedule);
    // Go back to the previous screen after selection
    Navigator.pop(context);
  }

  Future<List<CourseList>> _runSearch(String enteredKeyword) async {
    FetchClass _courses = FetchClass();
    if (currentSemester == null) {
      return []; // 또는 적절한 기본값 반환
    }
    String semester = currentSemester!;
    String querytype = 'code';

    List<CourseList> apiData = await _courses.getClassList(
        querytype: querytype, semester: semester, query: enteredKeyword);

    if (mounted) {
      setState(() {
        _foundCourses = apiData;
      });
    }
    return apiData;
  }

  void updateUI() {
    setState(() {
      // UI 업데이트 로직
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSearchKeywords();
    _fetchLatestSemester();
    // Initialize the keyword controller and add listener
    this._keywordController = TextEditingController();

    print('${widget.index}');
    // Initialize animation controller
    this._controller =
        AnimationController(duration: Duration(seconds: 2), vsync: this);
  }

  void _fetchLatestSemester() async {
    List<String> semesters = await fetchAllSemesters();
    if (semesters.isNotEmpty) {
      setState(() {
        currentSemester = semesters.last;
      });
    }
  }

  String formatSemester(String? semester) {
    if (semester == null) {
      return '202408';
    }

    String year = semester.substring(0, 4);
    String season = getSeasonFromSemester(semester);
    return "$season $year";
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _controller.dispose();

    super.dispose();
  }

  //검색어 로드
  Future<void> _loadSearchKeywords() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchKeywords = prefs.getStringList('searchKeywords') ?? [];
    });
  }

  //검색어 저장
  Future<void> _storeSearchKeyword(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    // Avoid storing duplicate and empty keywords.
    if (!_searchKeywords.contains(keyword) && keyword.isNotEmpty) {
      _searchKeywords.add(keyword);
      await prefs.setStringList('searchKeywords', _searchKeywords);
    }
  }

  Future<void> _deleteSearchKeyword(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    _searchKeywords.remove(keyword);
    await prefs.setStringList('searchKeywords', _searchKeywords);
    setState(() {}); // Update the UI to reflect the deletion.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    List<Color> tileColors =
        theme.brightness == Brightness.dark ? tileColorsDark : tileColorsLight;
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 20),
                      child: Text(
                        'Search',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 23, bottom: 0),
                      child: Text(
                        formatSemester(widget.semester),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 20, top: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape:
                          BoxShape.circle, // Ensures the container is circular
                    ),
                    child: IconButton(
                      icon: Icon(
                        FeatherIcons.x,
                        color: Theme.of(context).colorScheme.outline,
                      ),

                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                      padding: EdgeInsets.all(
                          5), // Remove padding to fit the icon well
                      constraints:
                          BoxConstraints(), // Remove constraints if necessary
                    ),
                  ),
                ),
              ],
            ),
            Padding(
                padding: EdgeInsets.only(
                    top: 15.0, bottom: 10.0, left: 15.0, right: 15.0),
                child: AnimatedTextField(
                    controller: _keywordController,
                    animationType: Animationtype.typer,
                    cursorColor: Theme.of(context).colorScheme.outline,
                    hintTexts: const [
                      'CMSC131 ',
                      'CHEM132 ',
                      'ENES140 ',
                      'BMGT310 ',
                      'MATH240 ',
                      'KORA201 ',
                    ],
                    animationDuration: Duration(milliseconds: 100000),
                    hintTextStyle: const TextStyle(
                      color: Colors.grey,
                      overflow: TextOverflow.ellipsis,
                    ),
                    decoration: InputDecoration(
                      fillColor: Theme.of(context).colorScheme.primary,
                      filled: true, // 배경색 채우기 활성화
                      contentPadding: EdgeInsets.symmetric(vertical: 15.0),
                      border: OutlineInputBorder(
                        // 기본 테두리 설정
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none, // 둘레 색 없애기
                      ),
                      focusedBorder: OutlineInputBorder(
                        // 포커스 됐을 때의 테두리 설정
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none, // 둘레 색 없애기
                      ),
                      hintText: 'Search Course',
                      prefixIcon: Icon(
                        FeatherIcons.search,
                        size: 25.0,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          _keywordController.clear();
                          setState(() {
                            _coursesFuture =
                                null; // Set to null when the search bar is cleared.
                            _foundCourses =
                                []; // Clear the list of found courses.
                          });
                        },
                        icon: Icon(
                          FeatherIcons.delete,
                          size: 20,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                    onSubmitted: (String value) async {
                      String formattedValue =
                          value.replaceAll(' ', ''); // Remove all spaces
                      setState(() {
                        _coursesFuture = _runSearch(formattedValue);
                      });
                    })),
            Expanded(
              child: FutureBuilder<List<CourseList>>(
                future: _coursesFuture,
                builder: (context, snapshot) {
                  if (_coursesFuture == null) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 0, left: 20),
                              child: Consumer<SavedSemesterProvider>(
                                builder: (context, semesterProvider, child) {
                                  return Text(
                                    'Recent',
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  );
                                },
                              ),
                            ),
                            Spacer(),
                          ],
                        ),
                        if (_searchKeywords.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              'No recent searches',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 16,
                              ),
                            ),
                          )
                        else
                          Container(
                              margin: EdgeInsets.only(left: 10, top: 5),
                              child: Wrap(
                                spacing: 8.0, // 가로 간격
                                runSpacing: 4.0, // 세로 간격
                                children: List.generate(_searchKeywords.length,
                                    (index) {
                                  return GestureDetector(
                                    onTap: () {
                                      // Update the TextEditingController to display the keyword
                                      _keywordController.text =
                                          _searchKeywords[index];
                                      // Trigger the search with the keyword
                                      setState(() {
                                        _coursesFuture = _runSearch(
                                            _searchKeywords[index].trim());
                                      });
                                    },
                                    child: Chip(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      shape: RoundedRectangleBorder(
                                        side: BorderSide(
                                            color: Colors.transparent),
                                        borderRadius: BorderRadius.horizontal(
                                          left: const Radius.circular(30),
                                          right: const Radius.circular(30),
                                        ),
                                      ),
                                      label: Text(
                                        _searchKeywords[index],
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline,
                                            fontSize: 15),
                                      ),
                                      onDeleted: () {
                                        _deleteSearchKeyword(_searchKeywords[
                                            index]); // 삭제 아이콘 클릭 시 해당 검색어를 삭제합니다.
                                      },
                                      deleteIcon: Icon(
                                        FeatherIcons.xCircle,
                                        size: 20,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline,
                                      ),
                                    ),
                                  );
                                }),
                              )),
                      ],
                    );

                    //    'Please enter a Course to search for courses',
                  } else if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return SingleChildScrollView(
                      child: Center(
                        child: Column(
                          children: List<Widget>.generate(
                              7, (index) => GroupLoading2(context)),
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (_foundCourses.isEmpty) {
                    // Add this condition.
                    return Center(
                      child: Text(
                        'No courses found.\nPlease try another keyword.',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    );
                  } else {
                    // Flatten the list of instructors.
                    List<InstructorCourse> instructorCourses = [];
                    for (var course in _foundCourses) {
                      if (course.sections != null) {
                        for (var section in course.sections!) {
                          if (section.meetings != null) {
                            for (var meeting in section.meetings!) {
                              instructorCourses.add(
                                  InstructorCourse(course, meeting, section));
                            }
                          }
                        }
                      }
                    }

                    return ListView.builder(
                      itemCount: _foundCourses.length,
                      itemBuilder: (context, courseIndex) {
                        var course = _foundCourses[courseIndex];
                        return Column(
                          children: course.sections?.map((section) {
                                // Collect formatted meeting times into a list
                                List<String> formattedMeetingTimes =
                                    section.meetings?.map((meeting) {
                                          DateTime startTime = DateFormat.Hm()
                                              .parse(meeting.startTime!);
                                          DateTime endTime = DateFormat.Hm()
                                              .parse(meeting.endTime!);
                                          String formattedStartTime =
                                              DateFormat('h:mm a')
                                                  .format(startTime);
                                          String formattedEndTime =
                                              DateFormat('h:mm a')
                                                  .format(endTime);

                                          return '${meeting.days} $formattedStartTime - $formattedEndTime';
                                        }).toList() ??
                                        [];

                                String meetingTimes =
                                    formattedMeetingTimes.join('\n');
                                return SimepleCourseTile(
                                  classes: course,
                                  sectionCode: section.code ??
                                      '', // Pass the section code
                                  instructorName: section.instructors?.first ??
                                      '', // Pass the first instructor's name
                                  icon: FeatherIcons.plusCircle,
                                  backgroundColor: Colors.white,
                                  index: courseIndex,
                                  onPressed: (context) {
                                    _handleCourseSelection(course);

                                    //    addToGroup(context, section, course);
                                    // Navigator.pop(context);
                                  },
                                  meetingTimes: meetingTimes,
                                  fullSeat: section.seats ?? 0,
                                  openSeat: section.openSeats ?? 0,
                                  waitlist: section.waitlist ?? 0,
                                );
                              }).toList() ??
                              [],
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool checkTimeConflict(
    ScheduleList newCourse, List<ScheduleList> existingCourses) {
  // Create a list of all day-time combinations for the new course.
  List<String> newCombinations = [];
  for (var meeting in newCourse.meetings!) {
    var days = meeting.days!.split('');
    var time = '${meeting.startTime}-${meeting.endTime}';
    for (var day in days) {
      newCombinations.add('$day-$time');
    }
  }

  // Check each existing course for conflicts.
  for (var existingCourse in existingCourses) {
    // Create a list of all day-time combinations for the existing course.
    List<String> existingCombinations = [];
    for (var meeting in existingCourse.meetings!) {
      var days = meeting.days!.split('');
      var time = '${meeting.startTime}-${meeting.endTime}';
      for (var day in days) {
        existingCombinations.add('$day-$time');
      }
    }

    // Check if any of the combinations overlap.
    if (newCombinations
        .any((element) => existingCombinations.contains(element))) {
      return true;
    }
  }

  return false;
}

ScheduleList convertCourseListToScheduleList(CourseList course) {
  // 예시로, 첫 번째 섹션의 정보를 사용하여 ScheduleList 객체를 생성합니다.
  // 실제 구현에서는 CourseList 구조와 필요에 따라 조정이 필요합니다.
  Section section = course.sections!.first;
  return ScheduleList(
      id: section.id,
      name: course.name,
      instructors: section.instructors,
      meetings: section.meetings
          ?.map((meeting) => ScheduleMeeting(
              building: meeting.building,
              room: meeting.room,
              days: meeting.days,
              startTime: meeting.startTime,
              endTime: meeting.endTime))
          .toList(),
      courseCode: course.courseCode,
      sectionCode: section.code,
      credits: course.credits,
      seats: section.seats,
      openSeats: section.openSeats,
      waitlist: section.waitlist);
}
