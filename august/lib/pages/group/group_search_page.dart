import 'package:animated_hint_textfield/animated_hint_textfield.dart';
import 'package:august/components/home/loading.dart';
import 'package:august/get_api/onboard/get_semester.dart';
import 'package:august/onboard/semester.dart';
import 'package:flutter/material.dart';
import '../../get_api/timetable/class.dart';
import '../../get_api/search/get_api.dart';
import '../../components/tile/class_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "package:flutter_feather_icons/flutter_feather_icons.dart";
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class GroupSearchPage extends StatefulWidget {
  final void Function(GroupList) onCourseSelected;
  final ValueNotifier<List<GroupList>> addedCoursesNotifier;
  final String? title;
  final String semester;

  GroupSearchPage({
    Key? key,
    required this.onCourseSelected,
    required this.addedCoursesNotifier,
    this.title,
    required this.semester,
  }) : super(key: key);

  @override
  State<GroupSearchPage> createState() => _GroupSearchPageState();
}

class InstructorCourse {
  final GroupList course;
  final GroupInstructor instructor;
  final List<GroupSection> sections;
  InstructorCourse(this.course, this.instructor, this.sections);
}

class _GroupSearchPageState extends State<GroupSearchPage>
    with SingleTickerProviderStateMixin {
  List<GroupList> _foundCourses = [];
  late TextEditingController _keywordController;
  Future<List<GroupList>>? _coursesFuture;
  List<String> _searchKeywords = [];

  void addToGroup(GroupList classes) {
    widget.onCourseSelected(classes);
  }

  void removeFromGroup(GroupList course) {
    widget.addedCoursesNotifier.value.remove(course);
  }

  bool hasMeetings(GroupList course) {
    for (var instructor in course.instructors!) {
      for (var section in instructor.sections!) {
        if (section.meetingsExist == false) {
          return false;
        }
      }
    }
    return true;
  }

  String formatSemester(String? semester) {
    if (semester == null) {
      return '202408';
    }

    String year = semester.substring(0, 4);
    String season = getSeasonFromSemester(semester);
    return "$season $year";
  }

  Future<List<GroupList>> _runSearch(String enteredKeyword) async {
    FetchGroup _courses = FetchGroup();

    String semester = widget.semester;
    String querytype = 'code';

    List<GroupList> apiData = await _courses.getGroupList(
        querytype: querytype, semester: semester, query: enteredKeyword);
    print("API Response: $apiData");

    if (mounted) {
      setState(() {
        _foundCourses = apiData;
      });
    }
    await _storeSearchKeyword(enteredKeyword);
    return apiData;
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
  void initState() {
    super.initState();
    // Initialize the keyword controller and add listener
    this._keywordController = TextEditingController();

    //검색어 저장
    _loadSearchKeywords();
  }

  @override
  void dispose() {
    _keywordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      child: Scaffold(
        extendBody: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          forceMaterialTransparency: true,
          leading: Row(
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
            ],
          ),
          leadingWidth: 500,
          toolbarHeight: 110,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle, // Ensures the container is circular
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.outline,
                  ),

                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  padding:
                      EdgeInsets.all(5), // Remove padding to fit the icon well
                  constraints:
                      BoxConstraints(), // Remove constraints if necessary
                ),
              ),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: EdgeInsets.only(
                    top: 0.0, bottom: 10.0, left: 15.0, right: 15.0),
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
                      hintText: 'Search Courses',
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
                        icon: Icon(FeatherIcons.delete,
                            size: 20,
                            color: Theme.of(context).colorScheme.outline),
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
              child: FutureBuilder<List<GroupList>>(
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
                  } else if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return SingleChildScrollView(
                      child: Center(
                        child: Column(
                          children: List<Widget>.generate(
                              7, (index) => GroupLoading1(context)),
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    print('Error: ${snapshot.error}');
                    // 사용자 인터페이스에서 에러 메시지 표시
                    return Center(
                      child: Text(
                        'Error... Try to restart the app',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    );
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
                    // Flatten the list of instructors.
                    List<InstructorCourse> instructorCourses = [];

                    for (var course in _foundCourses) {
                      // Create a map to track instructors and their sections
                      Map<String, List<GroupSection>> instructorSectionMap = {};

                      for (var instructor in course.instructors!) {
                        // Initialize the list for this instructor if not already done
                        instructorSectionMap.putIfAbsent(
                            instructor.name!, () => []);

                        // Add all sections of this instructor to the map
                        instructorSectionMap[instructor.name]!
                            .addAll(instructor.sections!);
                      }

                      // Now create InstructorCourse objects using the map
                      instructorSectionMap.forEach((instructorName, sections) {
                        var instructor = course.instructors!
                            .firstWhere((inst) => inst.name == instructorName);
                        instructorCourses.add(
                            InstructorCourse(course, instructor, sections));
                      });
                    }

                    return ListView.builder(
                      itemCount: instructorCourses.length +
                          ((instructorCourses.length < 4 ||
                                  instructorCourses.length % 5 == 0)
                              ? 1
                              : 0) +
                          (instructorCourses.length / 5).floor(),
                      itemBuilder: (context, index) {
                        int actualIndex = index - (index / 6).floor();

                        if ((instructorCourses.length < 4 &&
                                index == instructorCourses.length) ||
                            (index % 6 == 5)) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: 15,
                              left: 15,
                              right: 15,
                            ),
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.shadow,
                                    blurRadius: 10,
                                    offset: Offset(6, 4),
                                  ),
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.shadow,
                                    blurRadius: 10,
                                    offset: Offset(-2, 0),
                                  ),
                                ],
                              ),
                              child: Center(child: Text('Ad space')),
                            ),
                          );
                        } else if (actualIndex < instructorCourses.length) {
                          var course = instructorCourses[actualIndex].course;
                          var instructor =
                              instructorCourses[actualIndex].instructor;
                          var section = instructorCourses[actualIndex].sections;

                          return ClassTile(
                            classes: GroupList(
                              name: course.name,
                              courseCode: course.courseCode,
                              credits: course.credits,
                              instructors: [instructor],
                            ),
                            onPressed: (context) {
                              Navigator.pop(context);
                              // addToGroup(GroupList(
                              //   name: course.name,
                              //   courseCode: course.courseCode,
                              //   credits: course.credits,
                              //   instructors: [instructor],
                              // ));
                              if (hasMeetings(course)) {
                                addToGroup(GroupList(
                                  name: course.name,
                                  courseCode: course.courseCode,
                                  credits: course.credits,
                                  instructors: [instructor],
                                ));
                              } else {
                                addToGroup(GroupList(
                                  name: course.name,
                                  courseCode: course.courseCode,
                                  credits: course.credits,
                                  instructors: [instructor],
                                ));
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(
                                        textAlign: TextAlign.center,
                                        '${course.courseCode} (ONLINE)',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      content: Text(
                                        textAlign: TextAlign.center,
                                        'This course will not appear on the schedule.',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline,
                                            fontSize: 15,
                                            fontWeight: FontWeight.normal),
                                      ),
                                      actions: <Widget>[
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.of(context)
                                                .pop(); // 팝업 닫기
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 30),
                                            height: 55,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width -
                                                80,
                                            decoration: BoxDecoration(
                                                color: Colors.redAccent,
                                                borderRadius:
                                                    BorderRadius.circular(60)),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'OK',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                              }
                            },
                            icon: FeatherIcons.plusCircle,
                            backgroundColor:
                                Theme.of(context).colorScheme.background,
                            index: actualIndex,
                            sections: section,
                          );
                        }
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
