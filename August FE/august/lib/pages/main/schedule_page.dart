// ignore_for_file: avoid_print, unnecessary_string_interpolations

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:august/components/firebase/firebase_analytics.dart';
import 'package:august/components/indicator/scrolling_dots_effect.dart';
import 'package:august/components/indicator/smooth_page_indicator.dart';
import 'package:august/components/home/loading.dart';
import 'package:august/components/home/more.dart';
import 'package:august/const/device/device_util.dart';
import 'package:august/const/font/font.dart';
import 'package:august/const/icons/icons.dart';
import 'package:august/get_api/timetable/delete_timetable.dart';
import 'package:august/get_api/timetable/edit_timetable.dart';
import 'package:august/get_api/onboard/get_semester.dart';
import 'package:august/get_api/onboard/get_timetables.dart';
import 'package:august/get_api/timetable/schedule.dart';
import 'package:august/get_api/timetable/set_timetable_name.dart';
import 'package:august/login/login.dart';
import 'package:august/onboard/semester.dart';
import 'package:august/pages/search/search_page.dart';
import 'package:august/provider/courseprovider.dart';
import 'package:august/provider/semester_provider.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../components/timetable/timetable.dart';
import '../edit/edit_page.dart';
import '../group/group_page.dart';
import '../manual/manual_page.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SchedulePage extends StatefulWidget {
  SchedulePage({
    super.key,
  });
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with TickerProviderStateMixin {
  /*  --- for sharing and screenshot --- */
  final screenshotController = ScreenshotController();
  /* --- semester info handling ---- */
  String? currentSemester;
  int? currentSemesterInt;

  /* --- timetable handling ---- */
  List<TimeTables> _timetableCollection = [];
  List<TimeTables> savedTimeCollection = [];
  int currentIndex = 0;

  /* --- loading indicator for the timetable ----- */
  bool loadDone = false;
  bool isLoading = true;

  /* --- page controller ---- */
  late AnimationController _animationController;
  late final PageController _pageController;
  late ScrollController _dotIndicatorScrollController;

  /* --- order for the timetable */
  List<int> timetableOrder = [];
  int serverIndex = 0;

  Future<void> resetAnimations() async {
    await Future.delayed(const Duration(seconds: 1));
    await Future.delayed(const Duration(seconds: 1));
    return;
  }

  void initState() {
    super.initState();
    /* -- get the semeester info and load timetables */
    Future.delayed(Duration(seconds: 1), () {
      currentSemester =
          Provider.of<SemesterProvider>(context, listen: false).semester;
      currentSemesterInt = int.parse(currentSemester!);
      isLoading = true;
      Future.delayed(Duration.zero, () async {
        try {
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
    });

    _dotIndicatorScrollController = ScrollController();
    _pageController = PageController(
        // viewportFraction: 0.92,
        );
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
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

    // Call the reorderTimetable method
    reorderTimetable(currentSemester!, timetableOrder).then((_) {
      // After successful reordering, load timetable from the server
      loadTimetableFromServer(int.parse(currentSemester!)).then((_) {
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

    int semesterInt = int.parse(currentSemester!);
    if (currentSemester != null && !loadDone) {
      try {
        Future loadFuture = loadTimetableFromServer(semesterInt);
        await loadFuture;
      } catch (e) {
        print("Error during initialization: $e");
      }
    } else if (loadDone) {
      await loadTimetableFromServer(semesterInt);
    } else {
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

        savedTimeCollection = List<TimeTables>.from(_timetableCollection);

        print("저장되었슴");
      }
    } catch (e) {
      print("저장에 실패했습니다: $e");
    }
  }

  Future<void> loadTimetableFromServer(int semester) async {
    try {
      final timetableData = await getTimetableFromServer(semester);
      List<dynamic> timetablesJson = jsonDecode(timetableData!);
      timetableOrder = [];
      _timetableCollection = timetablesJson.map((timetable) {
        List<ScheduleList> sections = (timetable['sections'] as List)
            .map((section) => ScheduleList.fromJson(section))
            .toList();

        TimeTables newTimetable = TimeTables(
          name: timetable['name'],
          credits: timetable['credits'],
          order: timetable['order'],
          coursesData: [sections],
          pageController: PageController(),
        );

        timetableOrder.add(newTimetable.order!);

        return newTimetable;
      }).toList();
      Provider.of<CoursesProvider>(context, listen: false).timetableLength =
          timetableOrder.length;

      Provider.of<CoursesProvider>(context, listen: false).numCourses =
          _timetableCollection[0].coursesData[0].length;

      await saveTimetableToLocalStorage();
    } catch (e) {
      print("Error fetching timetable: $e");
    }
  }

  void _navigateToPageSemester() async {
    await Navigator.push<Map<String, dynamic>>(
      context,
      CupertinoPageRoute(
        builder: (BuildContext context) {
          return SemesterPage(
            onboard: false,
            goBack: () {},
            gonext: () {},
          );
        },
        fullscreenDialog: true,
      ),
    );
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('timetable');
    await prefs.setBool('loadDone', false);
    print("Timetable data cleared successfully.");
  }

  Future<void> share(int index, BuildContext context) async {
    try {
      HapticFeedback.lightImpact();
      final bytes = await screenshotController.captureFromLongWidget(
        InheritedTheme.captureAll(
          context,
          Material(
            child: SingleChildScrollView(
              child: savedTimeCollection.isNotEmpty
                  ? Screenshot(
                      controller: screenshotController,
                      child: Container(
                        child: SingleTimetable(
                          courses: savedTimeCollection[0].coursesData[0],
                          index: 0,
                          forceFixedTimeRange: false,
                        ),
                      ),
                    )
                  : Container(
                      child: Text('No timetable data available.'),
                    ),
            ),
          ),
        ),
        delay: Duration(milliseconds: 100),
        context: context,
      );
      await saveAndShare(bytes);
    } catch (e) {
      print("Error during screenshot and share: $e");
    }
  }

  Future<void> saveAndShare(Uint8List bytes) async {
    final time = DateTime.now().toIso8601String().replaceAll('.', '-');
    final directory = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();

    final image = File('${directory!.path}/$time.png');
    image.writeAsBytesSync(bytes);
    await Share.shareXFiles([XFile(image.path)]);
  }

  @override
  Widget build(BuildContext context) {
    final coursesProvider = Provider.of<CoursesProvider>(context);
    final currentIndexProv = Provider.of<CurrentIndexProvider>(context);

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
            overflowRules: DeviceUtils.isTablet(context)
                ? OverflowRules.only(bottom: true, top: true)
                : OverflowRules.only(bottom: true),
            child: DeviceUtils.isTablet(context) &&
                    DeviceUtils.isLandscape(context)
                ? isTablet(currentIndexProv)
                : isMobile(currentIndexProv),
          ),
        ),
      ),
    );
  }

  Widget isMobile(CurrentIndexProvider currentIndexProv) {
    return Column(
      children: [
        Row(
          children: [
            timeTableTitleAndSemester(),
            Spacer(),
            getHelp(context),
            // if (_timetableCollection.isNotEmpty) countTimeTable(),
          ],
        ),
        timeTableBuilder(currentIndexProv),
        DeviceUtils.isTablet(context)
            ? SizedBox(height: 10)
            : SizedBox(height: 0),
      ],
    );
  }

  Widget isTablet(CurrentIndexProvider currentIndexProv) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding:
                const EdgeInsets.only(left: 10, right: 10, bottom: 20, top: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: BorderRadius.circular(10),
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
                children: [
                  Row(
                    children: [
                      timeTableTitleAndSemester(),
                    ],
                  ),
                  timeTableBuilder(currentIndexProv),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding:
                const EdgeInsets.only(left: 10, right: 10, bottom: 20, top: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: BorderRadius.circular(10),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SearchPage(),
              ),
            ),
          ),
        ),
      ],
    );
  }

/* --- all the elements ---  */
  Widget timeTableBuilder(CurrentIndexProvider currentIndexProv) {
    return Expanded(
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int value) {
              if (value < timetableOrder.length) {
                serverIndex = timetableOrder[value];
              }

              Provider.of<CurrentIndexProvider>(context, listen: false)
                  .setCurrentIndex(value);
              setState(() {
                currentIndex = value;
              });
              if (currentIndex < _timetableCollection.length) {
                var currentCourses =
                    _timetableCollection[currentIndex].coursesData[0];
                currentCourses.forEach((course) {});
              }
              if (value >= 7 && value < _timetableCollection.length) {
                double scrollToPosition =
                    (value - 7) * 20.0; // '20.0'은 도트와 여백의 크기에 따라 조정해야 할 수 있습니다.
                if (_dotIndicatorScrollController.hasClients) {
                  _dotIndicatorScrollController.animateTo(
                    scrollToPosition,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              }
            },
            itemCount: _timetableCollection.length + 1,
            itemBuilder: (BuildContext ctx, int index) {
              if (index == _timetableCollection.length && !isLoading) {
                return GestureDetector(
                  onTap: () {},
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: createButton(),
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
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(width: 20),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
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
                                      "Main Schedule        ",
                                      key: ValueKey<int>(1),
                                      style: AugustFont.captionSmallBold(
                                        color: Colors.grey,
                                      ),
                                    )
                                  : Text(
                                      "Personal Schedule",
                                      key: ValueKey<int>(2),
                                      style: AugustFont.captionSmallBold(
                                        color: Colors.grey,
                                      ),
                                    ),
                            ),
                            Spacer(),
                            moreButton(currentIndexProv),
                          ],
                        ),
                      ),
                      //이게 타임테이블
                      Expanded(
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 30),
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
                bottomIndicator(),
              ],
            ),
        ],
      ),
    );
  }

  Widget moreButton(currentIndexProv) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: MoreButton(
        editSchedule: () {
          HapticFeedback.lightImpact();
          if (currentIndex < _timetableCollection.length) {
            checkAccessToken();
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              CupertinoPageRoute(
                fullscreenDialog: true,
                builder: (context) => EditPage(
                  index: currentIndex,
                  semester: currentSemester!,
                  name: _timetableCollection[currentIndex].name,
                ),
              ),
            );
          }
        },
        share: () => share(currentIndex, context),
        remove: () async {
          HapticFeedback.lightImpact();
          if (currentIndex < _timetableCollection.length) {
            // Trigger any access checks and user feedback
            checkAccessToken();
            HapticFeedback.mediumImpact();
            // Start any animations
            await _animationController.forward();
            // Remove the timetable from the collection
            setState(() {
              if (_timetableCollection.isNotEmpty &&
                  currentIndex < _timetableCollection.length) {
                _timetableCollection.removeAt(currentIndex);
                // Adjust currentIndex if necessary
                currentIndex = currentIndex > 0 ? currentIndex - 1 : 0;
              }
            });

            if (_pageController.hasClients) {
              _pageController.animateToPage(
                currentIndex,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }

            print('this will be deleted: $serverIndex');

            // Attempt to delete the timetable from the server
            try {
              await deleteTimetable(currentSemester!, serverIndex);
              print("Timetable deleted successfully");

              // Reload the timetable from the server
              await loadTimetableFromServer(int.parse(currentSemester!));
              print("Timetable reloaded successfully after delete");
            } catch (error) {
              print("Error during delete or reload operation: $error");
            } finally {
              // Always run these regardless of success or error
              setState(() {
                isLoading = false;
              });
              await resetAnimations();
            }
          }
        },
        setMain: () {
          HapticFeedback.lightImpact();
          if (currentIndex < _timetableCollection.length) {
            checkAccessToken();
            HapticFeedback.mediumImpact();
            setState(() {
              if (currentIndex > 0 &&
                  currentIndex < _timetableCollection.length) {
                final currentTimetable =
                    _timetableCollection.removeAt(currentIndex);
                _timetableCollection.insert(0, currentTimetable);
                currentIndex = 0;
              }
            });

            reorderTimetableIndex(serverIndex, timetableOrder);
            _pageController.animateToPage(
              currentIndex,
              duration:
                  const Duration(milliseconds: 500), // 애니메이션의 지속 시간을 설정합니다.
              curve: Curves.easeInOut, // 애니메이션의 속도 곡선을 설정합니다.
            );
            print("this is the order from the pageview $currentIndex");

            currentIndexProv.setCurrentIndex(currentIndex);
            print("this is the order from the pageview $currentIndex");
          }
        },
        currentIndex: currentIndex,
      ),
    );
  }

  Widget createButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 38, left: 10, right: 10),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height - 332,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AvatarGlow(
                startDelay: const Duration(milliseconds: 1000),
                glowColor: Colors.blueAccent,
                glowShape: BoxShape.circle,
                animate: true,
                curve: Curves.fastOutSlowIn,
                child: Container(
                  height: 70,
                  width: 70,
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent, // 원하는 배경 색상 설정
                    shape: BoxShape.circle, // 원형 모양 설정
                  ),
                  child: IconButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      checkAccessToken();
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            backgroundColor:
                                Theme.of(context).colorScheme.background,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                AnalyticsService().groupCreate();
                                Navigator.pop(context);
                                Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                        builder: (context) => GroupPage()));
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                height: 300,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      'Pick Your Favorite!',
                                      style: AugustFont.head1(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            height: 200,
                                            width: 200,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .shadow,
                                                  blurRadius: 10,
                                                  offset: const Offset(6, 4),
                                                ),
                                                BoxShadow(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .shadow,
                                                  blurRadius: 10,
                                                  offset: const Offset(-2, 0),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Transform.rotate(
                                                  angle: -5 * (pi / 180),
                                                  child: Image.asset(
                                                    'assets/icons/wand.png',
                                                    height: 80,
                                                    width: 80,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  'Auto\nGenerate',
                                                  style: AugustFont.head2(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .outline),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 20), // 버튼 사이의 간격
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              HapticFeedback.selectionClick();
                                              Navigator.pop(context);
                                              Navigator.push(
                                                context,
                                                CupertinoPageRoute(
                                                  builder: (context) =>
                                                      ManualPage(
                                                    index: currentIndex + 1,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              height: 200,
                                              width: 200,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .shadow,
                                                    blurRadius: 10,
                                                    offset: const Offset(6, 4),
                                                  ),
                                                  BoxShadow(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .shadow,
                                                    blurRadius: 10,
                                                    offset: const Offset(-2, 0),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Transform.rotate(
                                                    angle: 1 * (pi / 180),
                                                    child: Image.asset(
                                                      'assets/icons/manual.png',
                                                      height: 80,
                                                      width: 80,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Text(
                                                    'Manually\nCreate',
                                                    style: AugustFont.head2(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .outline),
                                                    textAlign: TextAlign.center,
                                                  ),
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
                    icon: Icon(
                      AugustIcons.add,
                      size: 40,
                    ),
                    color: Colors.white, // 아이콘 색상 설정
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                _timetableCollection.length > 1
                    ? 'Create More'
                    : 'Start Scheduling',
                textAlign: TextAlign.center,
                style: AugustFont.head1(
                    color: Theme.of(context).colorScheme.outline),
              ),
              Text(
                'Tap the plus button to get started',
                textAlign: TextAlign.center,
                style: AugustFont.subText(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget bottomIndicator() {
    return Positioned(
      bottom: 0,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              _pageController.animateToPage(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Row(
              children: [
                Container(
                  color: Colors.transparent,
                  height: 20,
                  width: MediaQuery.sizeOf(context).width,
                ),
                Container(
                  height: 20,
                  width: 20,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      bottomLeft: Radius.circular(30),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      AugustIcons.bottomLeft,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 20,
            width: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
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
                    activeDotColor: Theme.of(context).colorScheme.outline),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              _pageController.animateToPage(
                _timetableCollection.length,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Row(
              children: [
                Container(
                  height: 20,
                  width: 20,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      AugustIcons.bottomRight,
                      size: 12,
                    ),
                  ),
                ),
                Container(
                  color: Colors.transparent,
                  height: 20,
                  width: MediaQuery.sizeOf(context).width,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget timeTableTitleAndSemester() {
    return Padding(
      padding: const EdgeInsets.only(left: 15, top: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer<CurrentIndexProvider>(
            builder: (context, currentIndexProvider, child) {
              int currentIndex = currentIndexProvider.currentIndex;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (currentIndex < _timetableCollection.length) {
                    checkAccessToken();
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        fullscreenDialog: true,
                        builder: (context) => EditPage(
                          index: currentIndex,
                          semester: currentSemester!,
                          name: _timetableCollection[currentIndex].name,
                        ),
                      ),
                    );
                  }
                },
                child: Row(
                  children: [
                    Text(
                      isLoading
                          ? "Loading..."
                          : currentIndex >= _timetableCollection.length
                              ? "Create"
                              : _timetableCollection[currentIndex].name ==
                                      "Schedule"
                                  ? "Schedule ${currentIndex + 1}"
                                  : (_timetableCollection[currentIndex]
                                                  .name
                                                  ?.length ??
                                              0) >
                                          13
                                      ? "${_timetableCollection[currentIndex].name?.substring(0, 10)}..."
                                      : _timetableCollection[currentIndex]
                                              .name ??
                                          "Schedule",
                      style: AugustFont.head1(
                          color: Theme.of(context).colorScheme.outline),
                    ),
                  ],
                ),
              );
            },
          ),
          semesterButton(),
        ],
      ),
    );
  }

  Widget semesterButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _navigateToPageSemester();
      },
      child: Row(
        children: [
          Consumer<SemesterProvider>(
            builder: (context, semesterProvider, child) {
              return AnimatedSwitcher(
                duration:
                    const Duration(milliseconds: 300), // Animation duration
                transitionBuilder: (Widget child, Animation<double> animation) {
                  // Wrap child with a FadeTransition
                  return FadeTransition(opacity: animation, child: child);
                },

                child: Row(
                  key: ValueKey<String>(semesterProvider.semester),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatSemester(semesterProvider.semester),
                      style: AugustFont.subText(color: Colors.grey),
                    ),
                    if (formatSemester(semesterProvider.semester) != " ")
                      Icon(
                        AugustIcons.arrowRight,
                        color: Colors.grey,
                        size: 15,
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget countTimeTable() {
    return Padding(
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
            style: AugustFont.mainPageCount(
                color: Theme.of(context).colorScheme.outline),
          ),
        ),
      ),
    );
  }
}

void directToHelp() async {
  const url =
      'https://extra-mile.notion.site/August-Support-62cf34cf67954640b71f96b4af8eeda8?pvs=4';
  await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.inAppWebView,
  );
}

Widget getHelp(BuildContext context) {
  return GestureDetector(
    onTap: () {
      directToHelp();
    },
    child: Padding(
      padding: const EdgeInsets.only(right: 15),
      child: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.background,
        child: Center(
          child: Image.asset(
            'assets/icons/help.png',
            height: 25,
            width: 25,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
    ),
  );
}

class CurrentIndexProvider with ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }
}
