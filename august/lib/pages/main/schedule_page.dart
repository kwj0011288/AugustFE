// ignore_for_file: avoid_print, unnecessary_string_interpolations

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:august/components/home/button.dart';
import 'package:august/components/indicator/scrolling_dots_effect.dart';
import 'package:august/components/indicator/smooth_page_indicator.dart';
import 'package:august/components/home/loading.dart';
import 'package:august/components/profile/profile.dart';
import 'package:august/components/home/more.dart';
import 'package:august/get_api/timetable/delete_timetable.dart';
import 'package:august/get_api/timetable/edit_timetable.dart';
import 'package:august/get_api/onboard/get_semester.dart';
import 'package:august/get_api/onboard/get_timetables.dart';
import 'package:august/get_api/timetable/schedule.dart';
import 'package:august/get_api/timetable/set_timetable_name.dart';
import 'package:august/login/login.dart';
import 'package:august/onboard/profile.dart';
import 'package:august/onboard/semester.dart';
import 'package:august/pages/gpa/gpa_page.dart';
import 'package:august/pages/main/homepage.dart';
import 'package:august/pages/search/search_page.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pull_down_button/pull_down_button.dart';
import '../../components/timetable/timetable.dart';
import '../edit/edit_page.dart';
import '../group/group_page.dart';
import '../manual/manual_page.dart';
import '../profile/me_page.dart';
import "package:flutter_feather_icons/flutter_feather_icons.dart";
import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

class SchedulePage extends StatefulWidget {
  List<List<ScheduleList>> selectedCoursesData;
  final List<String> preloadedSemesters;
  final String semester;
  final List<String> departments;
  final bool guest;
  final bool firstTime;
  SchedulePage({
    super.key,
    this.selectedCoursesData = const [],
    required this.semester,
    this.departments = const [],
    this.guest = false,
    required this.firstTime,
    required this.preloadedSemesters,
  });
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with TickerProviderStateMixin {
  String? _semester;
  String formattedDate = DateFormat.MMMMEEEEd().format(DateTime.now());
  List<TimeTables> _timetableCollection = [];
  List<TimeTables> _firstTimeTable = [];
  int currentIndex = 0;
  int pageIndex = 0;
  String? selectedValue;
  int bottomIndex = 0;
  int totalCredits = 0;
  late AnimationController _animationController;
  late final PageController _pageController;
  late ScrollController _dotIndicatorScrollController;
  final PageDotController =
      PageController(viewportFraction: 0.8, keepPage: true);
  bool loadDone = false;
  bool isLoading = true;
  List<int> timetableOrder = [];
  int serverIndex = 0;

  void createScheduler(BuildContext context) {
    setState(() {
      var courseData =
          widget.selectedCoursesData[0]; // Accessing the first element safely

      _timetableCollection.add(TimeTables(
          coursesData: [courseData], pageController: _pageController));
      widget.selectedCoursesData.add(courseData);
      saveTimetableToLocalStorage(); // Saving timetable
    });
  }

  Future<void> loadSemesterInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedSemester = prefs.getString('semester');

    String formattedSemester =
        storedSemester ?? formatSemester(widget.preloadedSemesters.last);

    setState(() {
      _semester = formattedSemester;
    });
  }

  String formatSemester(String semester) {
    String year = semester.substring(0, 4);
    String season = getSeasonFromSemester(semester);
    return "$season $year";
  }

  Future<void> resetAnimations() async {
    await Future.delayed(const Duration(seconds: 1));
    await Future.delayed(const Duration(seconds: 1));
    return;
  }

  void initState() {
    super.initState();
    isLoading = true;

    _dotIndicatorScrollController = ScrollController();
    _pageController = PageController(
        // viewportFraction: 0.92,
        );
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    Future.delayed(Duration.zero, () async {
      try {
        await loadSemesterInfo();
        await initializePage();
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      } catch (error) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    });

    if (widget.semester.isNotEmpty) {
      selectedValue = widget.semester;
    }

    //애니메이션

    _timetableCollection = widget.selectedCoursesData
        .map((courseList) => TimeTables(
              coursesData: [courseList],
              pageController: PageController(),
            ))
        .toList();
  }

  @override
  void dispose() {
    _dotIndicatorScrollController.dispose();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void reorderTimetableIndex(int moveIndex, List<int> currentList) {
    // Remove the index and re-insert at the beginning to reorder
    currentList.remove(moveIndex);
    currentList.insert(0, moveIndex);
    timetableOrder = currentList;

    String ogsem = getOriginalSemester(_semester!);

    // Call the reorderTimetable method
    reorderTimetable(ogsem, timetableOrder).then((_) {
      // After successful reordering, load timetable from the server
      loadTimetableFromServer(int.parse(ogsem)).then((_) {
        // When done loading, set isLoading to false

        print("Timetable loaded successfully");
      }).catchError((error) {
        // Handle errors from loading the timetable
        print("Error loading timetable: $error");
      });
    }).catchError((error) {
      // Handle errors from reordering the timetable
      print("Error reordering timetable: $error");
    });
  }

  Future<void> initializePage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedSemesterString = prefs.getString('semester') ??
        formatSemester(widget.preloadedSemesters.last);

    loadDone = prefs.getBool('loadDone') ?? false;
    if (!loadDone) {
      // If loadDone is not true, set it to false initially and then change to true after 1 minute
      await prefs.setBool('loadDone', false); // Set initially to false
      Future.delayed(const Duration(seconds: 3), () async {
        await prefs.setBool('loadDone', true); // Change to true after 1 minute
        if (mounted) {
          setState(() {
            loadDone = true; // Update the state to reflect the new value
          });
        }
        print('check check check: $loadDone');
      });
    }
    print('check check check: $loadDone');
    // loadDone 값을 불러옵니다. 값이 없다면 기본적으로 false를 반환합니다.
    storedSemesterString = getOriginalSemester(storedSemesterString);
    int semesterInt = int.parse(storedSemesterString);
    if (storedSemesterString != null && !loadDone) {
      try {
        Future loadFuture = loadTimetableFromServer(semesterInt);
        await loadFuture;
      } catch (e) {
        // Handle errors, such as parsing errors or issues with loading data from the server/local storage
        print("Error during initialization: $e");
      }
    } else if (loadDone) {
      await loadTimetableFromServer(semesterInt);
    } else {
      // Handle the case where semester information is not available or is invalid
      print("Semester information is missing or invalid.");
    }
  }

  Future<void> saveTimetableToLocalStorage() async {
    try {
      if (_timetableCollection.isNotEmpty) {
        List<List<Map<String, dynamic>>> coursesDataMapList =
            _timetableCollection
                .map((timeTable) => timeTable.coursesData[0]
                    .map((scheduleItem) => scheduleItem.toJson())
                    .toList())
                .toList();

        String jsonString = jsonEncode(coursesDataMapList);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('timetable', jsonString);

        print("저장되었슴");
      }
    } catch (e) {
      print("저장에 실패했습니다: $e");
    }
  }

  // This function checks if two lists of ScheduleList are identical.
  bool areIdentical(List<ScheduleList> list1, List<ScheduleList> list2) {
    // If the lengths are not equal, they can't be identical.
    if (list1.length != list2.length) return false;

    // Sort both lists by course ID before comparing.
    list1.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
    list2.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));

    for (int i = 0; i < list1.length; ++i) {
      if (list1[i].id != list2[i].id) return false;
    }

    return true;
  }

  Future<void> loadTimetableFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('timetable');

    if (jsonString != null) {
      List<dynamic> coursesDataMapList = jsonDecode(jsonString);

      _timetableCollection = coursesDataMapList
          .map((courseList) => TimeTables(
                coursesData: [
                  (courseList as List)
                      .map(
                          (scheduleItem) => ScheduleList.fromJson(scheduleItem))
                      .toList()
                ],
                pageController: PageController(),
              ))
          .toList()
          .cast<TimeTables>();

      // Remove duplicates from _timetableCollection
      for (int i = 0; i < _timetableCollection.length - 1; ++i) {
        for (int j = i + 1; j < _timetableCollection.length; ++j) {
          if (areIdentical(_timetableCollection[i].coursesData[0],
              _timetableCollection[j].coursesData[0])) {
            _timetableCollection.removeAt(j);
            --j;
          }
        }
      }
      _timetableCollection
          .removeWhere((timeTable) => timeTable.coursesData[0].isEmpty);
    }
  }

  Future<void> loadTimetableFromServer(int semester) async {
    try {
      // Simulating getting the JSON response as a string
      final timetableData = await getTimetableFromServer(semester);

      // Decoding the JSON string to a dynamic structure
      List<dynamic> timetablesJson = jsonDecode(timetableData!);

      // Initialize the list to store orders of timetables
      timetableOrder = []; // Ensuring it is not null and empty before starting

      // Parsing each timetable in the list
      _timetableCollection = timetablesJson.map((timetable) {
        List<ScheduleList> sections = (timetable['sections'] as List)
            .map((section) => ScheduleList.fromJson(section))
            .toList();

        // Create a TimeTables object
        TimeTables newTimetable = TimeTables(
          name: timetable['name'],
          credits: timetable['credits'],
          order: timetable['order'],
          coursesData: [
            sections
          ], // Wrapping in another list to match your data structure
          pageController:
              PageController(), // Assuming each timetable gets its own page controller
        );

        // Store the order of the timetable
        timetableOrder.add(newTimetable.order!);

        return newTimetable;
      }).toList();

      if (_timetableCollection.isNotEmpty) {
        _firstTimeTable.add(_timetableCollection.first);
      }

      // Now that the timetable collection and orders are updated, save it to local storage
      await saveTimetableToLocalStorage();
    } catch (e) {
      print("Error fetching timetable: $e");
    }
  }

  void _navigateToPageSemester() async {
    var result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.pop(context);
          },
          child: DraggableScrollableSheet(
            initialChildSize: 1,
            maxChildSize: 1,
            minChildSize: 1,
            builder: (BuildContext context, ScrollController scrollController) {
              var preloadedSemesters =
                  Provider.of<SemestersProvider>(context, listen: false)
                      .semesters;
              return GestureDetector(
                onTap: () {},
                child: SemesterPage(
                  preloadedSemesters: preloadedSemesters,
                  onboard: false,
                  goBack: () {},
                  gonext: () {},
                ),
              );
            },
          ),
        );
      },
    );
    if (result != null && result['semester'] != _semester) {
      // Update the semester and reload the page
      setState(() {
        _semester = result['semester'] ?? _semester;
      });
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
          transitionDuration: const Duration(
              milliseconds: 200), // Adjust the speed of the fade transition
        ),
      );
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Remove a specific key
    await prefs.remove('timetable');
    await prefs.setBool('loadDone', false);
    print("Timetable data cleared successfully.");
  }

  Future<void> loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Fetch the semester and convert it
    String? storedSemester = prefs.getString('semester');
    if (storedSemester != null) {
      storedSemester = _semester;
    } else {
      _semester = ' '; // Use a default value if there's no stored value
    }
  }

  Future<void> _editTimetableName(int index) async {
    TextEditingController nameController =
        TextEditingController(text: _timetableCollection[index].name);
    final newName = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: Container(
            color: Theme.of(context).colorScheme.background,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: <Widget>[
                Text(
                  "Edit Timetable Name",
                  style: TextStyle(
                    fontSize: 25,
                    color: Theme.of(context).colorScheme.outline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                CupertinoTextField(
                  autofocus: true,
                  controller: nameController,
                  placeholder: "",
                  placeholderStyle: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  cursorColor: Theme.of(context).colorScheme.outline,
                  padding: const EdgeInsets.all(15),
                  onSubmitted: (value) {
                    // 'Done' 버튼을 눌렀을 때의 동작
                    checkAccessToken();
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop(value);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() {
        _timetableCollection[index].name = newName;
        saveTimetableToLocalStorage(); // 새 이름을 저장합니다.
      });
      // int? testindex = _timetableCollection[currentIndex].order;
      String? testSemester = getOriginalSemester(_semester!);
      print('testSemester: $_semester');
      updateTimetableName(testSemester, index, newName);
    }
  }

  Future<void> removeGPACourses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("savedCourses");
  }

  Widget GPAButton(String text, Color buttonColor, final VoidCallback onTap) {
    TextStyle buttonTextStyle = const TextStyle(
      // Define your text style here
      fontSize: 15,
      fontWeight: FontWeight.bold,
    );

    double textWidth = calculateTextWidth(text, buttonTextStyle, context);
    double buttonWidth = textWidth + 15; // Add some padding to the text width

    return Container(
      width: buttonWidth,
      height: 25,
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(timetableOrder);
    print(_semester);
    final currentIndexProv = Provider.of<CurrentIndexProvider>(context);
    _timetableCollection
        .removeWhere((timeTable) => timeTable.coursesData.isEmpty);

    return WillPopScope(
      onWillPop: () async {
        return Future.value(false);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: ColorfulSafeArea(
            bottomColor: Colors.white.withOpacity(0),
            overflowRules: const OverflowRules.only(bottom: true),
            child: Column(
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 15, top: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Consumer<CurrentIndexProvider>(
                            builder: (context, currentIndexProvider, child) {
                              int currentIndex =
                                  currentIndexProvider.currentIndex;
                              return Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (currentIndex ==
                                          _timetableCollection.length) {
                                      } else {
                                        _editTimetableName(serverIndex);
                                      }
                                    },
                                    child: Text(
                                      isLoading
                                          ? "Loading..."
                                          : currentIndex >=
                                                  _timetableCollection.length
                                              ? "Create"
                                              : _timetableCollection[
                                                              currentIndex]
                                                          .name ==
                                                      "Schedule"
                                                  ? "Schedule ${currentIndex + 1}"
                                                  : (_timetableCollection[
                                                                      currentIndex]
                                                                  .name
                                                                  ?.length ??
                                                              0) >
                                                          13
                                                      ? "${_timetableCollection[currentIndex].name?.substring(0, 10)}..."
                                                      : _timetableCollection[
                                                                  currentIndex]
                                                              .name ??
                                                          "Schedule",
                                      style: TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _navigateToPageSemester();
                            },
                            child: Row(
                              children: [
                                Consumer<SavedSemesterProvider>(
                                  builder: (context, semesterProvider, child) {
                                    return Text(
                                      widget.firstTime
                                          ? formatSemester(
                                              widget.preloadedSemesters.last)
                                          : '${semesterProvider.selectedSemester}',
                                      style: const TextStyle(
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
                    if (_timetableCollection.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 15),
                        child: Container(
                          width: _timetableCollection.length < 10 ? 120 : 130,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          child: Center(
                            child: Text(
                              "${_timetableCollection.length.toString()} Schedules",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (int value) {
                          if (value < timetableOrder.length) {
                            serverIndex = timetableOrder[value];
                            print(
                                "this is the order from pageview $currentIndex");
                            print("this is the order from server $serverIndex");
                          }

                          Provider.of<CurrentIndexProvider>(context,
                                  listen: false)
                              .setCurrentIndex(value);
                          setState(() {
                            currentIndex = value;
                          });
                          if (currentIndex < _timetableCollection.length) {
                            var currentCourses =
                                _timetableCollection[currentIndex]
                                    .coursesData[0];
                            currentCourses.forEach((course) {
                              //print('Course ID: ${course.id}');
                            });
                          }
                          if (value >= 7 &&
                              value < _timetableCollection.length) {
                            double scrollToPosition = (value - 7) *
                                20.0; // '20.0'은 도트와 여백의 크기에 따라 조정해야 할 수 있습니다.
                            _dotIndicatorScrollController.animateTo(
                              scrollToPosition,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        itemCount: _timetableCollection.length + 1,
                        itemBuilder: (BuildContext ctx, int index) {
                          if (index == _timetableCollection.length &&
                              !isLoading) {
                            return GestureDetector(
                              onTap: () => createScheduler(context),
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.topCenter,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 38, left: 10, right: 10),
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        height:
                                            MediaQuery.of(context).size.height -
                                                332,
                                        decoration: BoxDecoration(
                                          // color: Theme.of(context)
                                          //     .colorScheme
                                          //     .primaryContainer,
                                          color: Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              AvatarGlow(
                                                startDelay: const Duration(
                                                    milliseconds: 1000),
                                                glowColor: Colors.blueAccent,
                                                glowShape: BoxShape.circle,
                                                animate: true,
                                                curve: Curves.fastOutSlowIn,
                                                child: Container(
                                                  height: 70,
                                                  width: 70,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Colors
                                                        .blueAccent, // 원하는 배경 색상 설정
                                                    shape: BoxShape
                                                        .circle, // 원형 모양 설정
                                                  ),
                                                  child: IconButton(
                                                    onPressed: () {
                                                      checkAccessToken();
                                                      showDialog(
                                                        context: context,
                                                        builder: (BuildContext
                                                            context) {
                                                          return Dialog(
                                                            shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            20)),
                                                            child:
                                                                GestureDetector(
                                                              onTap: () {
                                                                Navigator.pop(
                                                                    context); // Close the bottom sheet
                                                                Navigator.push(
                                                                  context,
                                                                  CupertinoPageRoute(
                                                                      builder:
                                                                          (context) =>
                                                                              GroupPage(
                                                                                semester: widget.semester,
                                                                              )),
                                                                );
                                                              },
                                                              child: Container(
                                                                width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width,
                                                                height:
                                                                    300, // 컨테이너의 높이 조정
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        20),
                                                                child: Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .center,
                                                                  children: <Widget>[
                                                                    const Text(
                                                                      'Pick Your Favorite!',
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            25,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                    ),
                                                                    const SizedBox(
                                                                        height:
                                                                            20),
                                                                    Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Expanded(
                                                                          child:
                                                                              Container(
                                                                            height:
                                                                                200,
                                                                            width:
                                                                                200,
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: Theme.of(context).colorScheme.primaryContainer,
                                                                              borderRadius: BorderRadius.circular(20),
                                                                              boxShadow: [
                                                                                BoxShadow(
                                                                                  color: Theme.of(context).colorScheme.shadow,
                                                                                  blurRadius: 10,
                                                                                  offset: const Offset(6, 4),
                                                                                ),
                                                                                BoxShadow(
                                                                                  color: Theme.of(context).colorScheme.shadow,
                                                                                  blurRadius: 10,
                                                                                  offset: const Offset(-2, 0),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                            child:
                                                                                Column(
                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                                              children: [
                                                                                const Icon(FeatherIcons.layout, size: 70, color: Colors.blueAccent),
                                                                                const SizedBox(height: 5),
                                                                                Text(
                                                                                  'Auto\nGenerate',
                                                                                  style: TextStyle(
                                                                                    fontSize: 20,
                                                                                    fontWeight: FontWeight.bold,
                                                                                    color: Theme.of(context).colorScheme.outline,
                                                                                  ),
                                                                                  textAlign: TextAlign.center,
                                                                                ),
                                                                                // Text(
                                                                                //   textAlign: TextAlign.center,
                                                                                //   'Save your time!',
                                                                                //   style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.black),
                                                                                // ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                20), // 버튼 사이의 간격
                                                                        Expanded(
                                                                          child:
                                                                              GestureDetector(
                                                                            onTap:
                                                                                () {
                                                                              List<ScheduleList> coursesData = [];
                                                                              if (currentIndex < widget.selectedCoursesData.length) {
                                                                                coursesData = widget.selectedCoursesData[currentIndex];
                                                                              }

                                                                              Navigator.pop(context); // Close the bottom sheet
                                                                              Navigator.push(
                                                                                context,
                                                                                CupertinoPageRoute(
                                                                                  builder: (context) => ManualPage(
                                                                                    coursesData: coursesData,
                                                                                    index: currentIndex + 1,
                                                                                    semester: widget.semester,
                                                                                  ),
                                                                                ),
                                                                              );
                                                                            },
                                                                            child:
                                                                                Container(
                                                                              height: 200,
                                                                              width: 200,
                                                                              decoration: BoxDecoration(
                                                                                color: Theme.of(context).colorScheme.primaryContainer,
                                                                                borderRadius: BorderRadius.circular(20),
                                                                                boxShadow: [
                                                                                  BoxShadow(
                                                                                    color: Theme.of(context).colorScheme.shadow,
                                                                                    blurRadius: 10,
                                                                                    offset: const Offset(6, 4),
                                                                                  ),
                                                                                  BoxShadow(
                                                                                    color: Theme.of(context).colorScheme.shadow,
                                                                                    blurRadius: 10,
                                                                                    offset: const Offset(-2, 0),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              child: Column(
                                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                                children: [
                                                                                  const Icon(
                                                                                    FeatherIcons.search,
                                                                                    size: 70,
                                                                                    color: Colors.amberAccent,
                                                                                  ),
                                                                                  const SizedBox(height: 5),
                                                                                  Text(
                                                                                    'Manually\nCreate',
                                                                                    style: TextStyle(
                                                                                      fontSize: 20,
                                                                                      fontWeight: FontWeight.bold,
                                                                                      color: Theme.of(context).colorScheme.outline,
                                                                                    ),
                                                                                    textAlign: TextAlign.center,
                                                                                  ),
                                                                                  // Text(
                                                                                  //   textAlign: TextAlign.center,
                                                                                  //   "Got plenty of time?",
                                                                                  //   style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.black),
                                                                                  // ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    },
                                                    icon: const Icon(
                                                      FeatherIcons.plus,
                                                      size: 40,
                                                    ),
                                                    color: Colors
                                                        .white, // 아이콘 색상 설정
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 15),
                                              Text(
                                                _timetableCollection.length > 1
                                                    ? 'Create More'
                                                    : 'Start Scheduling',
                                                textAlign: TextAlign
                                                    .center, // 텍스트를 가운데 정렬
                                                style: TextStyle(
                                                  fontSize: 25,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .outline,
                                                ),
                                              ),
                                              const Text(
                                                'Create your schedules.\nTap the plus button to get started.',
                                                textAlign: TextAlign
                                                    .center, // 텍스트를 가운데 정렬
                                                style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else if (isLoading) {
                            return GroupLoading4(context);
                          } else {
                            return Container(
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 7),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 20),
                                        AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 250),
                                          transitionBuilder: (Widget child,
                                              Animation<double> animation) {
                                            // Using a fade transition and maintaining alignment to the start
                                            return FadeTransition(
                                              opacity: animation,
                                              child: AlignTransition(
                                                alignment: Tween<Alignment>(
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerLeft,
                                                ).animate(animation),
                                                child: child,
                                              ),
                                            );
                                          },
                                          child: currentIndex == 0
                                              ? Text(
                                                  "This schedule is for the friends and GPA page.",
                                                  key: ValueKey<int>(
                                                      1), // Unique key to trigger animation
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey,
                                                  ),
                                                )
                                              : Text(
                                                  "Try to make this schedule the main one.             ",
                                                  key: ValueKey<int>(
                                                      2), // Unique key to trigger animation
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                        ),
                                        Spacer(),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 20),
                                          child: MoreButton(
                                            editSchedule: () {
                                              HapticFeedback.lightImpact();
                                              if (currentIndex <
                                                  _timetableCollection.length) {
                                                checkAccessToken();
                                                HapticFeedback.mediumImpact();
                                                Navigator.push(
                                                  context,
                                                  CupertinoPageRoute(
                                                    fullscreenDialog: true,
                                                    builder: (context) =>
                                                        EditPage(
                                                      index: currentIndex,
                                                      semester: widget.semester,
                                                      name:
                                                          _timetableCollection[
                                                                  currentIndex]
                                                              .name,
                                                    ),
                                                  ),
                                                );
                                                saveTimetableToLocalStorage();
                                              }
                                              ;
                                            },
                                            editName: () {
                                              HapticFeedback.lightImpact();
                                              checkAccessToken();
                                              _editTimetableName(currentIndex);
                                            },
                                            remove: () async {
                                              HapticFeedback.lightImpact();
                                              if (currentIndex <
                                                  _timetableCollection.length) {
                                                // Trigger any access checks and user feedback
                                                checkAccessToken();
                                                HapticFeedback.mediumImpact();

                                                // Start any animations
                                                await _animationController
                                                    .forward();

                                                // Remove the timetable from the collection
                                                setState(() {
                                                  if (_timetableCollection
                                                          .isNotEmpty &&
                                                      currentIndex <
                                                          _timetableCollection
                                                              .length) {
                                                    _timetableCollection
                                                        .removeAt(currentIndex);
                                                    // Adjust currentIndex if necessary
                                                    currentIndex =
                                                        currentIndex > 0
                                                            ? currentIndex - 1
                                                            : 0;
                                                  }
                                                });

                                                // Navigate the page controller to the new current index
                                                if (_pageController
                                                    .hasClients) {
                                                  _pageController.animateToPage(
                                                    currentIndex,
                                                    duration: const Duration(
                                                        milliseconds: 500),
                                                    curve: Curves.easeInOut,
                                                  );
                                                }

                                                // Get semester string for API call
                                                String? testSemester =
                                                    getOriginalSemester(
                                                        _semester!);
                                                print(
                                                    'this will be deleted: $serverIndex');

                                                // Attempt to delete the timetable from the server
                                                try {
                                                  await deleteTimetable(
                                                      testSemester,
                                                      serverIndex);
                                                  print(
                                                      "Timetable deleted successfully");

                                                  // Reload the timetable from the server
                                                  await loadTimetableFromServer(
                                                      int.parse(testSemester));
                                                  print(
                                                      "Timetable reloaded successfully after delete");
                                                } catch (error) {
                                                  print(
                                                      "Error during delete or reload operation: $error");
                                                } finally {
                                                  // Always run these regardless of success or error
                                                  setState(() {
                                                    isLoading = false;
                                                  });
                                                  await resetAnimations();
                                                  await saveTimetableToLocalStorage();
                                                }
                                              }
                                            },
                                            setMain: () {
                                              HapticFeedback.lightImpact();
                                              if (currentIndex <
                                                  _timetableCollection.length) {
                                                checkAccessToken();
                                                HapticFeedback.mediumImpact();
                                                setState(() {
                                                  if (currentIndex > 0 &&
                                                      currentIndex <
                                                          _timetableCollection
                                                              .length) {
                                                    final currentTimetable =
                                                        _timetableCollection
                                                            .removeAt(
                                                                currentIndex);
                                                    _timetableCollection.insert(
                                                        0, currentTimetable);
                                                    currentIndex = 0;
                                                  }
                                                });

                                                _pageController.animateToPage(
                                                  currentIndex,
                                                  duration: const Duration(
                                                      milliseconds:
                                                          500), // 애니메이션의 지속 시간을 설정합니다.
                                                  curve: Curves
                                                      .easeInOut, // 애니메이션의 속도 곡선을 설정합니다.
                                                );
                                                removeGPACourses();
                                                print(
                                                    "this is the order from the pageview $currentIndex");
                                                reorderTimetableIndex(
                                                    serverIndex,
                                                    timetableOrder);
                                                // print(
                                                //     "Index to change $serverIndex");

                                                currentIndexProv
                                                    .setCurrentIndex(
                                                        currentIndex);
                                                saveTimetableToLocalStorage();
                                              }
                                            },
                                            currentIndex: currentIndex,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  //이게 타임테이블
                                  Expanded(
                                    child: Stack(
                                      alignment: Alignment.topCenter,
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 30),
                                          child: _timetableCollection[index],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                      if (_timetableCollection.isNotEmpty)
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Positioned(
                              bottom: 0,
                              child: Container(
                                height: 20,
                                width: 100,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  //   borderRadius: BorderRadius.circular(30),
                                  // border: Border.all(color: Colors.white),
                                ),
                                child: Center(
                                  child: SmoothPageIndicator(
                                    controller: _pageController!,
                                    count: _timetableCollection.length + 1,
                                    effect: ScrollingDotsEffect(
                                        activeStrokeWidth: 2,
                                        activeDotScale: 1.3,
                                        maxVisibleDots: 5,
                                        radius: 8,
                                        spacing: 8,
                                        dotHeight: 8,
                                        dotWidth: 8,
                                        dotColor: Colors.grey,
                                        activeDotColor: Theme.of(context)
                                            .colorScheme
                                            .outline),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 130,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  _pageController.animateToPage(
                                    0,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: Container(
                                  height: 20,
                                  width: 20,
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(30),
                                      bottomLeft: Radius.circular(30),
                                      // border: Border.all(color: Colors.white),
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      FeatherIcons.arrowLeft,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 130,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  _pageController?.animateToPage(
                                    _timetableCollection.length,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: Container(
                                  height: 20,
                                  width: 20,
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(30),
                                      bottomRight: Radius.circular(30),
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      FeatherIcons.arrowRight,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TimetableCountProvider with ChangeNotifier {
  int _count;

  TimetableCountProvider(this._count);

  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }

  void setCount(int value) {
    _count = value;
    notifyListeners();
  }
}

class CurrentIndexProvider with ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }
}

class EditState extends ChangeNotifier {
  bool _isEdited = false;

  bool get isEdited => _isEdited;

  void setEdit(bool value) {
    _isEdited = value;
    notifyListeners();
  }
}

class SetMainState extends ChangeNotifier {
  bool _isSetMain = false;

  bool get isSetMain => _isSetMain;

  void setSetMain(bool value) {
    _isSetMain = value;
    notifyListeners();
  }
}

class RemoveState extends ChangeNotifier {
  bool _isRemoved = false;

  bool get isRemoved => _isRemoved;

  void setRemove(bool value) {
    _isRemoved = value;
    notifyListeners();
  }
}

int getTotalCredits(List<ScheduleList> scheduleList) {
  int totalCredits = 0;
  for (var schedule in scheduleList) {
    totalCredits += schedule.credits ?? 0; // if credit is null, add 0
  }
  return totalCredits;
}

class TotalCreditProvider with ChangeNotifier {
  int _totalCredits;

  TotalCreditProvider(int totalCredits) : _totalCredits = totalCredits;

  int get totalCredits => _totalCredits;

  void setTotalCredits(int value) {
    _totalCredits = value;
    notifyListeners(); // Notify listeners to rebuild UI
  }

  set totalCredits(int value) {
    _totalCredits = value;
    notifyListeners(); // Notify listeners to rebuild UI
  }
}
