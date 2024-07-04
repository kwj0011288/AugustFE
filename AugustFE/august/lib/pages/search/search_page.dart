import 'package:animated_hint_textfield/animated_hint_textfield.dart';
import 'package:august/components/tile/search_tile.dart';
import 'package:august/get_api/onboard/get_semester.dart';
import 'package:august/get_api/search/simple_sections.dart';
import 'package:august/onboard/semester.dart';
import 'package:august/pages/main/homepage.dart';
import 'package:august/pages/profile/me_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../components/home/loading.dart';
import '../../get_api/timetable/class.dart';
import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:intl/intl.dart';
import "package:flutter_feather_icons/flutter_feather_icons.dart";
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  final String semester;
  SearchPage({
    Key? key,
    required this.semester,
  }) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class InstructorCourse {
  final CourseList course;
  final Section section;

  InstructorCourse(this.course, this.section);
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  List<CourseList> _foundCourses = [];
  late TextEditingController _keywordController;
  late Future<List<CourseList>>? _coursesFuture = null;
  late AnimationController _controller;
  String? currentSemester;
  Uint8List? profilePhoto;
  List<String> _searchKeywords = [];

  Future<List<CourseList>> _runSearch(String enteredKeyword) async {
    FetchCourse _courses = FetchCourse();

    String querytype = 'code';

    List<CourseList> apiData = await _courses.getCourseList(
        querytype: querytype,
        semester: getOriginalSemester(currentSemester!),
        query: enteredKeyword);

    if (mounted) {
      setState(() {
        _foundCourses = apiData;
      });
    }
    await _storeSearchKeyword(enteredKeyword);
    return apiData;
  }

  String formatSemester(String semester) {
    String year = semester.substring(0, 4);
    String season = getSeasonFromSemester(semester);
    return "$season $year";
  }

  void _navigateToPageSemester() async {
    var result = await Navigator.push<Map<String, dynamic>>(
      context,
      CupertinoPageRoute(
        builder: (BuildContext context) {
          return SemesterPage(
            preloadedSemesters:
                Provider.of<SemestersProvider>(context, listen: false)
                    .semesters,
            onboard: false,
            goBack: () {},
            gonext: () {},
          );
        },
        fullscreenDialog:
            true, // Set to true if you want the page to slide up from the bottom like a modal
      ),
    );
    if (result != null) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      );
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // Remove a specific key
      await prefs.remove('timetable');
      await prefs.setBool('loadDone', false);
      print("Timetable data cleared successfully.");
    }
  }

  @override
  void initState() {
    super.initState();
    currentSemester = (widget.semester);

    // Initialize the keyword controller and add listener
    this._keywordController = TextEditingController();

    // Initialize animation controller
    this._controller =
        AnimationController(duration: Duration(seconds: 2), vsync: this);

    //검색어 저장
    _loadSearchKeywords();
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
  void dispose() {
    _keywordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("Current hello: $currentSemester"); // Add this line
    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: ColorfulSafeArea(
          bottomColor: Colors.white.withOpacity(0),
          overflowRules: OverflowRules.only(bottom: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 15, top: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Search',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _navigateToPageSemester();
                            HapticFeedback.mediumImpact();
                          },
                          child: Row(
                            children: [
                              Consumer<SavedSemesterProvider>(
                                builder: (context, semesterProvider, child) {
                                  return Text(
                                    '${semesterProvider.selectedSemester}',
                                    style: TextStyle(
                                        fontSize: 15, color: Colors.grey),
                                  );
                                },
                              ),
                              const Icon(
                                Icons.keyboard_arrow_right,
                                color: Colors.grey,
                                size: 15,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  // Padding(
                  //   padding:
                  //       const EdgeInsets.only(left: 15, right: 10, top: 15),
                  //   child: GestureDetector(
                  //     onTap: () {
                  //       HapticFeedback.mediumImpact();
                  //       Navigator.pop(context);
                  //     },
                  //     child: CircleAvatar(
                  //       backgroundColor: Theme.of(context).colorScheme.primary,
                  //       foregroundColor:
                  //           Theme.of(context).colorScheme.background,
                  //       child: Center(
                  //         child: Icon(
                  //           FeatherIcons.x,
                  //           color: Theme.of(context).colorScheme.outline,
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(
                    top: 15.0, bottom: 15.0, left: 10.0, right: 10.0),
                child: AnimatedTextField(
                    animationType: Animationtype.typer,
                    cursorColor: Theme.of(context).colorScheme.outline,
                    controller: _keywordController,
                    hintTexts: const [
                      'CMSC131 ',
                      'CHEM132 ',
                      'ENES140 ',
                      'BMGT310 ',
                      'MATH240 ',
                      'KORA201 ',
                    ],
                    animationDuration: Duration(milliseconds: 500),
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
                      prefixIcon: Icon(
                        FeatherIcons.search,
                        size: 25.0,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
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
                      setState(() {
                        _coursesFuture = _runSearch(value.trim());
                      });
                    }),
              ),
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
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
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
                                  children: List.generate(
                                      _searchKeywords.length, (index) {
                                    return InkWell(
                                      onTap: () {
                                        _keywordController.text =
                                            _searchKeywords[index];
                                        // Trigger search with the keyword when the chip is tapped
                                        setState(() {
                                          _coursesFuture = _runSearch(
                                              _searchKeywords[index].trim());
                                        });
                                      },
                                      child: Chip(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary,
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
                            if (section.instructors != null) {
                              instructorCourses
                                  .add(InstructorCourse(course, section));
                            }
                          }
                        }
                      }

                      return ListView.builder(
                        itemCount: _foundCourses.length, // 수업 목록 길이 설정
                        itemBuilder: (context, courseIndex) {
                          var course = _foundCourses[courseIndex];
                          List<Widget> widgets = []; // 섹션과 광고를 포함할 위젯 리스트
                          int sectionsCount = course.sections?.length ?? 0;

                          // 각 코스의 섹션을 순회하면서 위젯 리스트에 추가
                          for (int i = 0; i < sectionsCount; i++) {
                            var section = course.sections![i];
                            List<String> formattedMeetingDetails = section
                                    .meetings
                                    ?.map((meeting) {
                                  DateTime startTime =
                                      DateFormat.Hm().parse(meeting.startTime!);
                                  DateTime endTime =
                                      DateFormat.Hm().parse(meeting.endTime!);
                                  String formattedStartTime =
                                      DateFormat('h:mm a').format(startTime);
                                  String formattedEndTime =
                                      DateFormat('h:mm a').format(endTime);
                                  return '${meeting.days} $formattedStartTime - $formattedEndTime (${meeting.building} ${meeting.room})';
                                }).toList() ??
                                [];

                            String meetingTimes =
                                formattedMeetingDetails.join('\n');

                            // 섹션 위젯 추가
                            widgets.add(SearchTile(
                              classes: course,
                              sectionCode: section.code ?? '',
                              instructorName: section.instructors?.first ?? '',
                              backgroundColor: Colors.white, // 배경색 지정 로직 필요
                              index: courseIndex,
                              meetingTimes: meetingTimes,
                              fullSeat: section.seats ?? 0,
                              openSeat: section.openSeats ?? 0,
                              waitlist: section.waitlist ?? 0,
                              holdfile: section.holdfile ?? 0,
                            ));

                            // 3개보다 많은 섹션이 있을 경우, 5번째 섹션마다 광고 삽입
                            if (sectionsCount > 3 && (i + 1) % 5 == 0) {
                              widgets.add(
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 15,
                                    left: 15,
                                    right: 15,
                                  ),
                                  child: Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .shadow,
                                          blurRadius: 10,
                                          offset: Offset(6, 4),
                                        ),
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .shadow,
                                          blurRadius: 10,
                                          offset: Offset(-2, 0),
                                        ),
                                      ],
                                    ),
                                    child: Center(child: Text('Ad space')),
                                  ),
                                ),
                              );
                            }
                          }

                          // 3개 이하의 섹션이 있고, 섹션이 하나 이상 있는 경우, 리스트의 마지막에 광고 삽입
                          if (sectionsCount > 1 && sectionsCount <= 4) {
                            widgets.add(
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 15,
                                  left: 15,
                                  right: 15,
                                ),
                                child: Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .shadow,
                                        blurRadius: 10,
                                        offset: Offset(6, 4),
                                      ),
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .shadow,
                                        blurRadius: 10,
                                        offset: Offset(-2, 0),
                                      ),
                                    ],
                                  ),
                                  child: Center(child: Text('Ad space')),
                                ),
                              ),
                            );
                          }

                          return Column(children: widgets);
                        },
                      );
                    }
                  },
                ),
              ),
              SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}
