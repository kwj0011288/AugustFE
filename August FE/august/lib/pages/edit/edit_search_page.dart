import 'dart:convert';

import 'package:animated_hint_textfield/animated_hint_textfield.dart';
import 'package:august/components/ad/ad_list.dart';
import 'package:august/const/font/font.dart';
import 'package:august/const/icons/icons.dart';
import 'package:august/provider/courseprovider.dart';
import 'package:august/components/tile/simple_course_tile.dart';
import 'package:august/const/theme/dark_theme.dart';
import 'package:august/const/theme/light_theme.dart';
import 'package:august/get_api/onboard/get_semester.dart';
import 'package:august/onboard/semester.dart';
import 'package:august/provider/semester_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../components/home/loading.dart';
import '../../get_api/timetable/class.dart';
import 'package:provider/provider.dart';
import '../../get_api/search/get_api.dart';
import '../../get_api/timetable/schedule.dart';
import 'package:intl/intl.dart';
import "package:flutter_feather_icons/flutter_feather_icons.dart";
import 'package:shared_preferences/shared_preferences.dart';

class EditSearchPage extends StatefulWidget {
  final ValueNotifier<List<ScheduleList>> addedCoursesNotifier;
  final String? title;
  final int? index;
  final String semester;
  EditSearchPage({
    Key? key,
    required this.addedCoursesNotifier,
    this.title,
    this.index,
    required this.semester,
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
  List<ScheduleList> _courseList = [];

/* --------------------------------------------------------*/
  void _initializeCourseList() {
    final coursesProvider =
        Provider.of<CoursesProvider>(context, listen: false);
    setState(() {
      _courseList =
          coursesProvider.courses; // Copying the courses from the provider
    });
    for (var course in _courseList) {
      print('Course ID: ${course.id}, Course Name: ${course.name}');
    }
  }

/* --------------------------------------------------------*/
  void removeFromGroup(CourseList course) {
    widget.addedCoursesNotifier.value.remove(course);
  }

  /* --------------------------*/
  bool _hasTimeConflict(ScheduleList newCourse, ScheduleList existingCourse) {
    for (var newMeeting in newCourse.meetings!) {
      for (var existingMeeting in existingCourse.meetings!) {
        // Ensure that both meetings have defined days
        if (newMeeting.days != null && existingMeeting.days != null) {
          var newDays = Set.from(newMeeting.days!.split(''));
          var existingDays = Set.from(existingMeeting.days!.split(''));

          // Check if the days intersect
          if (newDays.intersection(existingDays).isNotEmpty) {
            var newStart = DateFormat.Hm().parse(newMeeting.startTime!);
            var newEnd = DateFormat.Hm().parse(newMeeting.endTime!);
            var existingStart =
                DateFormat.Hm().parse(existingMeeting.startTime!);
            var existingEnd = DateFormat.Hm().parse(existingMeeting.endTime!);

            // Check for any time overlap
            if ((newStart.isBefore(existingEnd) &&
                    newEnd.isAfter(existingStart)) ||
                (existingStart.isBefore(newEnd) &&
                    existingEnd.isAfter(newStart))) {
              print(
                  'Time Conflict Detected between ${newMeeting.startTime} - ${newMeeting.endTime} and ${existingMeeting.startTime} - ${existingMeeting.endTime}');
              return true; // There is a conflict, return immediately
            }
          }
        }
      }
    }
    print('No Time Conflict Detected');
    return false; // No conflict found after all checks
  }

/* --------------------------*/
  void _handleCourseSelection(CourseList course, Section section) {
    // Convert the selected course to a ScheduleList object
    ScheduleList newSchedule = convertCourseListToScheduleList(course, section);
    bool conflictDetected = false;

    // Check for conflicts with all existing courses
    for (var existingCourse in _courseList) {
      if (_hasTimeConflict(newSchedule, existingCourse)) {
        Navigator.of(context).pop();
        // If a conflict is detected, show dialog and set flag
        conflictDetected = true;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                textAlign: TextAlign.center,
                "Time Conflict",
                style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              content: Text(
                textAlign: TextAlign.center,
                "This course conflicts with\none of your selected courses.",
                style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 15,
                    fontWeight: FontWeight.normal),
              ),
              actions: <Widget>[
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(); // 팝업 닫기
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    height: 55,
                    width: MediaQuery.of(context).size.width - 80,
                    decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(60)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'OK',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );

        break;
      }
    }

    // If no conflicts were detected, add the course
    if (!conflictDetected) {
      Provider.of<CoursesProvider>(context, listen: false)
          .addCourseToCurrentTimetableforEditPage(newSchedule);
      Provider.of<CoursesProvider>(context, listen: false)
          .additionalCourseforEditPage(newSchedule);
      Navigator.pop(context);
    }
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

  @override
  void initState() {
    super.initState();

    _initializeCourseList();

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
                        style: AugustFont.head3(
                            color: Theme.of(context).colorScheme.outline),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 23, bottom: 0),
                      child: Text(
                        formatSemester(widget.semester),
                        style: AugustFont.subText(color: Colors.grey),
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
                    style: AugustFont.textField(
                      color: Theme.of(context).colorScheme.outline,
                    ),
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
                    animationDuration: Duration(milliseconds: 500),
                    hintTextStyle: AugustFont.textField(
                      color: Colors.grey,
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
                              child: Consumer<SemesterProvider>(
                                builder: (context, semesterProvider, child) {
                                  return Text(
                                    'Recent',
                                    style: AugustFont.head2(
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                    ),
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
                              style: AugustFont.subText2(
                                color: Theme.of(context).colorScheme.onSurface,
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
                                        style: AugustFont.chip(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
                                        ),
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
                        style: AugustFont.head2(
                          color: Theme.of(context).colorScheme.outline,
                        ),
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
                        List<Widget> widgets = [];
                        int sectionsCount = course.sections?.length ?? 0;

                        // 각 코스의 섹션을 순회하면서 위젯 리스트에 추가
                        for (int i = 0; i < sectionsCount; i++) {
                          var section = course.sections![i];
                          List<String> formattedMeetingTimes =
                              section.meetings?.map((meeting) {
                                    DateTime startTime = DateFormat.Hm()
                                        .parse(meeting.startTime!);
                                    DateTime endTime =
                                        DateFormat.Hm().parse(meeting.endTime!);
                                    String formattedStartTime =
                                        DateFormat('h:mm a').format(startTime);
                                    String formattedEndTime =
                                        DateFormat('h:mm a').format(endTime);
                                    return '${meeting.days} $formattedStartTime - $formattedEndTime';
                                  }).toList() ??
                                  [];
                          String meetingTimes =
                              formattedMeetingTimes.join('\n');

                          widgets.add(SimepleCourseTile(
                            classes: course,
                            sectionCode:
                                section.code ?? '', // Pass the section code
                            instructorName: section.instructors?.first ??
                                '', // Pass the first instructor's name
                            icon: AugustIcons.addCoursetoGroup,
                            backgroundColor: Colors.white,
                            index: courseIndex,
                            onPressed: (context) {
                              _handleCourseSelection(course, section);
                            },
                            meetingTimes: meetingTimes,
                            fullSeat: section.seats ?? 0,
                            openSeat: section.openSeats ?? 0,
                            waitlist: section.waitlist ?? 0,
                            holdfile: section.holdfile ?? 0,
                          ));

                          // 3개보다 많은 섹션이 있을 경우, 5번째 섹션마다 광고 삽입
                          if (sectionsCount > 3 && (i + 1) % 5 == 0) {
                            widgets.add(
                              googleAdMobContainer(isGroup: false),
                            );
                          }
                        }

                        // 3개 이하의 섹션이 있고, 섹션이 하나 이상 있는 경우, 리스트의 마지막에 광고 삽입
                        if (sectionsCount > 1 && sectionsCount <= 4) {
                          widgets.add(
                            googleAdMobContainer(isGroup: false),
                          );
                        }

                        return Column(children: widgets);
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

ScheduleList convertCourseListToScheduleList(
    CourseList course, Section section) {
  // 예시로, 첫 번째 섹션의 정보를 사용하여 ScheduleList 객체를 생성합니다.
  // 실제 구현에서는 CourseList 구조와 필요에 따라 조정이 필요합니다.
  return ScheduleList(
      id: section.id,
      name: course.name,
      courseCode: course.courseCode,
      sectionCode: section.code,
      instructors: section.instructors,
      meetings: section.meetings
          ?.map((meeting) => ScheduleMeeting(
              building: meeting.building,
              room: meeting.room,
              days: meeting.days,
              startTime: meeting.startTime,
              endTime: meeting.endTime))
          .toList(),
      credits: course.credits,
      seats: section.seats,
      openSeats: section.openSeats,
      waitlist: section.waitlist);
}
