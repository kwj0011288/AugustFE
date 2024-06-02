// ignore_for_file: avoid_print, unnecessary_string_interpolations

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:august/components/button.dart';
import 'package:august/components/loading.dart';
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
import '../../components/timetable.dart';
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
  Uint8List? profilePhoto;
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

  Future<void> loadProfilePhoto() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Load name
    // Load image
    String? base64Image = prefs.getString('contactPhoto');

    if (base64Image != null) {
      setState(() {
        profilePhoto = base64Decode(base64Image);
      });
    }
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
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    Future.delayed(Duration.zero, () async {
      try {
        await loadSemesterInfo();
        await loadProfilePhoto();
        _listenForPhotoChanges();
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
    final photoNotifier =
        Provider.of<ProfilePhotoNotifier>(context, listen: false);
    if (photoNotifier.photo != null && mounted) {
      setState(() {
        profilePhoto = photoNotifier.photo;
      });
    }
  }

  @override
  void dispose() {
    _dotIndicatorScrollController.dispose();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _listenForPhotoChanges() {
    final photoNotifier =
        Provider.of<ProfilePhotoNotifier>(context, listen: false);
    photoNotifier.addListener(() {
      if (mounted) {
        setState(() {
          profilePhoto = photoNotifier.photo;
        });
      }
    });
  }

  void reorderTimetableIndex(int moveIndex, List<int> currentList) {
    currentList.remove(moveIndex);
    currentList.insert(0, moveIndex);
    timetableOrder = currentList;
    String ogsem = getOriginalSemester(_semester!);
    reorderTimetable(ogsem, timetableOrder);
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
        Future loadFuture = widget.firstTime
            ? loadTimetableFromLocalStorage()
            : loadTimetableFromServer(semesterInt);
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
      int? testindex = _timetableCollection[currentIndex].order;
      String? testSemester = getOriginalSemester(_semester!);
      print('testSemester: $_semester');
      updateTimetableName(testSemester, testindex!, newName);
    }
  }

  void _navigateToPage() async {
    showCupertinoModalBottomSheet<Map<String, dynamic>>(
      context: context,
      topRadius: const Radius.circular(30),
      duration: const Duration(milliseconds: 350),
      backgroundColor: Colors.black.withOpacity(0.8),
      builder: (BuildContext context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.pop(
                context); // Close the bottom sheet when the area outside the sheet is tapped
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
              if (notification.metrics.pixels ==
                  notification.metrics.maxScrollExtent) {}
              return true;
            },
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.55,
              maxChildSize: 0.85,
              minChildSize: 0.55,
              builder: (BuildContext context,
                  ScrollController sheetScrollController) {
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap:
                      () {}, // Prevent the outer GestureDetector from closing the sheet when the sheet itself is tapped
                  child: Mypage(
                    selectedSemester: _semester!, // Set your initial values
                    departments: widget.departments,
                    scrollController: sheetScrollController,
                    isFirst: widget.firstTime,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
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
                      padding: const EdgeInsets.only(left: 12, top: 15),
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
                                        _editTimetableName(currentIndex);
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
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 15,
                        right: 0,
                        top: 15,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      GPAPage(
                                semester: _semester!,
                                firstTimeTable: _firstTimeTable,
                              ),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                var begin = const Offset(0.0, 1.0);
                                var end = Offset.zero;
                                var curve = Curves.ease;

                                var tween = Tween(begin: begin, end: end)
                                    .chain(CurveTween(curve: curve));

                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        child: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.background,
                          child: Center(
                            child: Icon(
                              Icons.school_outlined,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 15,
                        right: 0,
                        top: 15,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      SearchPage(semester: _semester!),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                var begin = const Offset(0.0, 1.0);
                                var end = Offset.zero;
                                var curve = Curves.ease;

                                var tween = Tween(begin: begin, end: end)
                                    .chain(CurveTween(curve: curve));

                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        child: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.background,
                          child: Center(
                            child: Icon(
                              FeatherIcons.search,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 15,
                        right: 15,
                        top: 15,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _navigateToPage();
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.grey,
                          foregroundColor:
                              Theme.of(context).colorScheme.background,
                          backgroundImage: profilePhoto != null
                              ? MemoryImage(profilePhoto!)
                              : null,
                          child: profilePhoto == null
                              ? Image.asset('assets/icons/memoji.png')
                              : null,
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
                                        const Spacer(),
                                        const SizedBox(width: 10),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 20),
                                          child: PullDownButton(
                                            itemBuilder:
                                                (BuildContext context) {
                                              return <PullDownMenuEntry>[
                                                PullDownMenuItem(
                                                  title: 'Move to First',
                                                  icon: FeatherIcons.star,
                                                  onTap: () {
                                                    if (currentIndex <
                                                        _timetableCollection
                                                            .length) {
                                                      checkAccessToken();
                                                      HapticFeedback
                                                          .mediumImpact();
                                                      setState(() {
                                                        if (currentIndex > 0 &&
                                                            currentIndex <
                                                                _timetableCollection
                                                                    .length) {
                                                          final currentTimetable =
                                                              _timetableCollection
                                                                  .removeAt(
                                                                      currentIndex);
                                                          _timetableCollection
                                                              .insert(0,
                                                                  currentTimetable);
                                                          currentIndex = 0;
                                                        }
                                                      });

                                                      _pageController
                                                          .animateToPage(
                                                        currentIndex,
                                                        duration: const Duration(
                                                            milliseconds:
                                                                500), // 애니메이션의 지속 시간을 설정합니다.
                                                        curve: Curves
                                                            .easeInOut, // 애니메이션의 속도 곡선을 설정합니다.
                                                      );
                                                      removeGPACourses();

                                                      reorderTimetableIndex(
                                                          serverIndex,
                                                          timetableOrder);
                                                      print(
                                                          "Index to change $serverIndex");

                                                      currentIndexProv
                                                          .setCurrentIndex(
                                                              currentIndex);
                                                      saveTimetableToLocalStorage();
                                                    }
                                                  },
                                                ),
                                                //   if (currentIndex == 0)
                                                PullDownMenuItem(
                                                  title: 'Edit Schedule',
                                                  icon: FeatherIcons.edit2,
                                                  onTap: () {
                                                    if (currentIndex <
                                                        _timetableCollection
                                                            .length) {
                                                      checkAccessToken();
                                                      HapticFeedback
                                                          .mediumImpact();
                                                      Navigator.push(
                                                        context,
                                                        CupertinoPageRoute(
                                                          builder: (context) =>
                                                              EditPage(
                                                            index: serverIndex,
                                                            semester:
                                                                widget.semester,
                                                            name: _timetableCollection[
                                                                    currentIndex]
                                                                .name,
                                                          ),
                                                        ),
                                                      );
                                                      saveTimetableToLocalStorage();
                                                    }
                                                    ;
                                                  },
                                                ),
                                                PullDownMenuItem(
                                                  title: 'Edit Name',
                                                  icon: FeatherIcons.type,
                                                  onTap: () {
                                                    checkAccessToken();
                                                    _editTimetableName(
                                                        serverIndex);
                                                  },
                                                ),
                                                const PullDownMenuDivider
                                                    .large(),
                                                PullDownMenuItem(
                                                  title: 'Remove',
                                                  icon: FeatherIcons.trash,
                                                  isDestructive: true,
                                                  onTap: () async {
                                                    if (currentIndex <
                                                        _timetableCollection
                                                            .length) {
                                                      checkAccessToken();
                                                      HapticFeedback
                                                          .mediumImpact();

                                                      await _animationController
                                                          .forward(); // Start the animation
                                                      setState(
                                                        () {
                                                          if (_timetableCollection
                                                                  .isNotEmpty &&
                                                              currentIndex <
                                                                  _timetableCollection
                                                                      .length) {
                                                            _timetableCollection
                                                                .removeAt(
                                                                    currentIndex);
                                                            if (currentIndex >
                                                                0) {
                                                              currentIndex--;
                                                            }
                                                          }
                                                          //   cmsc216
                                                          if (_pageController
                                                              .hasClients) {
                                                            _pageController
                                                                .animateToPage(
                                                              currentIndex,
                                                              duration:
                                                                  const Duration(
                                                                      milliseconds:
                                                                          500),
                                                              curve: Curves
                                                                  .easeInOut,
                                                            );
                                                          }

                                                          // int? testindex =
                                                          //     _timetableCollection[
                                                          //                 currentIndex]
                                                          //             .order! -
                                                          //         1; // 이거 고쳐야됌
                                                          // print(
                                                          //     "Test Index ${testindex}");

                                                          String? testSemester =
                                                              getOriginalSemester(
                                                                  _semester!);

//3

                                                          print(
                                                              "Test Semester : ${testSemester}");

                                                          deleteTimetable(
                                                              testSemester,
                                                              serverIndex);
                                                          print(
                                                              getOriginalSemester(
                                                                  _semester!));
                                                        },
                                                      );
                                                      await Future.delayed(
                                                          const Duration(
                                                              milliseconds:
                                                                  500));
                                                      await resetAnimations();
                                                      saveTimetableToLocalStorage();
                                                    }
                                                    saveTimetableToLocalStorage();
                                                  },
                                                ),
                                                // PullDownMenuItem(
                                                //   title: 'Delete All',
                                                //   icon: FeatherIcons.trash2,
                                                //   isDestructive: true,
                                                //   onTap: () async {
                                                //     bool? confirmDelete =
                                                //         await showCupertinoModalPopup<
                                                //             bool>(
                                                //       context: context,
                                                //       builder: (BuildContext
                                                //           context) {
                                                //         return CupertinoActionSheet(
                                                //           title: const Text(
                                                //               'This will delete all schedules\nexcept the first schedule.'),
                                                //           actions: <CupertinoActionSheetAction>[
                                                //             CupertinoActionSheetAction(
                                                //               child: const Text(
                                                //                 'Remove',
                                                //                 style: TextStyle(
                                                //                     color: CupertinoColors
                                                //                         .destructiveRed,
                                                //                     fontWeight:
                                                //                         FontWeight
                                                //                             .normal),
                                                //               ),
                                                //               onPressed: () {
                                                //                 Navigator.pop(
                                                //                     context,
                                                //                     true); // Returns true on tap
                                                //               },
                                                //               isDestructiveAction:
                                                //                   true,
                                                //             ),
                                                //           ],
                                                //           cancelButton:
                                                //               CupertinoActionSheetAction(
                                                //             child: const Text(
                                                //               'Cancel',
                                                //               style: TextStyle(
                                                //                   color: CupertinoColors
                                                //                       .activeBlue,
                                                //                   fontWeight:
                                                //                       FontWeight
                                                //                           .normal),
                                                //             ),
                                                //             onPressed: () {
                                                //               Navigator.pop(
                                                //                   context,
                                                //                   false); // Returns false on tap
                                                //             },
                                                //           ),
                                                //         );
                                                //       },
                                                //     );

                                                //     // Check if the user confirmed the deletion
                                                //     if (confirmDelete == true) {
                                                //       // Place your existing deletion logic here
                                                //       if (_timetableCollection
                                                //               .length >
                                                //           1) {
                                                //         HapticFeedback
                                                //             .mediumImpact();
                                                //         await _animationController
                                                //             .forward(); // Start the animation

                                                //         setState(() {
                                                //           // Remove all timetables except the first one
                                                //           _timetableCollection
                                                //               .removeRange(
                                                //                   1,
                                                //                   _timetableCollection
                                                //                       .length);
                                                //         });

                                                //         await Future.delayed(
                                                //             Duration(
                                                //                 milliseconds:
                                                //                     500));
                                                //         await resetAnimations();
                                                //         saveTimetableToLocalStorage();
                                                //         Provider.of<CurrentIndexProvider>(
                                                //                 context,
                                                //                 listen: false)
                                                //             .setCurrentIndex(
                                                //                 currentIndex);
                                                //         Provider.of<RemoveState>(
                                                //                 context,
                                                //                 listen: false)
                                                //             .setRemove(true);
                                                //         saveTimetableToLocalStorage();
                                                //       }
                                                //     }
                                                //   },
                                                // ),
                                              ];
                                            },
                                            buttonBuilder:
                                                (BuildContext context,
                                                    Future<void> Function()
                                                        showMenu) {
                                              return GestureDetector(
                                                onTap: () {
                                                  HapticFeedback.mediumImpact();
                                                  showMenu();
                                                },
                                                child: const Icon(
                                                  FeatherIcons.moreHorizontal,
                                                  size: 20,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  //이게 타임테이블
                                  Expanded(
                                    child: Stack(
                                      alignment: Alignment.bottomCenter,
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 50),
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
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            bottom: 100,
                            child: _timetableCollection.isNotEmpty
                                ? Container(
                                    height: 45,
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(30),
                                      // border: Border.all(color: Colors.white),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            FeatherIcons.star,
                                            size: currentIndex == 0 ? 22 : 18,
                                          ),
                                          color: currentIndex == 0
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .outline
                                              : Colors.grey,
                                          onPressed: () {
                                            HapticFeedback.mediumImpact();
                                            _pageController.animateToPage(
                                              0,
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              curve: Curves.easeInOut,
                                            );
                                          },
                                        ),
                                        Container(
                                          width: min(
                                              _timetableCollection.length *
                                                  20.0,
                                              MediaQuery.of(context)
                                                      .size
                                                      .width -
                                                  250),
                                          child: Center(
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              controller:
                                                  _dotIndicatorScrollController,
                                              child: Row(
                                                children: List<Widget>.generate(
                                                  _timetableCollection.length +
                                                      1, // +1 for the extra page
                                                  (index) {
                                                    if (index == 0) {
                                                      return const SizedBox
                                                          .shrink(); // Home 버튼을 위한 공간
                                                    } else if (index ==
                                                        _timetableCollection
                                                            .length) {
                                                      return const SizedBox
                                                          .shrink(); // Add 버튼을 위한 공간
                                                    } else {
                                                      return GestureDetector(
                                                        onTap: () {
                                                          HapticFeedback
                                                              .mediumImpact();
                                                          _pageController
                                                              .animateToPage(
                                                            index,
                                                            duration:
                                                                const Duration(
                                                                    milliseconds:
                                                                        300),
                                                            curve: Curves
                                                                .easeInOut,
                                                          );
                                                        },
                                                        child:
                                                            AnimatedContainer(
                                                          duration:
                                                              const Duration(
                                                                  milliseconds:
                                                                      300),
                                                          margin:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      5),
                                                          height:
                                                              currentIndex ==
                                                                      index
                                                                  ? 15
                                                                  : 10,
                                                          width: currentIndex ==
                                                                  index
                                                              ? 15
                                                              : 10,
                                                          decoration:
                                                              BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color: currentIndex ==
                                                                    index
                                                                ? Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .outline
                                                                : Colors.grey,
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            FeatherIcons.plus,
                                            size: currentIndex ==
                                                    _timetableCollection.length
                                                ? 25
                                                : 20,
                                          ),
                                          color: currentIndex ==
                                                  _timetableCollection.length
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .outline
                                              : Colors.grey,
                                          onPressed: () {
                                            HapticFeedback.mediumImpact();
                                            _pageController.animateToPage(
                                              _timetableCollection.length,
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              curve: Curves.easeInOut,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(),
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
