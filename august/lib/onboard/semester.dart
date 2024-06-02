import 'package:august/components/button.dart';
import 'package:august/components/courseprovider.dart';
import 'package:august/get_api/onboard/get_semester.dart';
import 'package:august/login/login.dart';
import 'package:august/pages/main/homepage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pull_down_button/pull_down_button.dart';
import "package:flutter_feather_icons/flutter_feather_icons.dart";

class SemesterPage extends StatefulWidget {
  final List<String> preloadedSemesters;
  final bool onboard;
  final VoidCallback goBack;
  final VoidCallback gonext;
  SemesterPage({
    Key? key,
    required this.preloadedSemesters,
    required this.onboard,
    required this.goBack,
    required this.gonext,
  }) : super(key: key);

  @override
  _SemesterPageState createState() => _SemesterPageState();
}

class _SemesterPageState extends State<SemesterPage> {
  String? _selectSemester;

  String? _selectOriginalSemester;
  late Future<void> _loadUserFuture;

  late List<String> semestersList = [];
  late String currentSemester = '';
  final FocusNode _semesterFocusNode = FocusNode();

  @override
  void dispose() {
    super.dispose();
  }

// initState에서 _loadInfo 호출
  @override
  void initState() {
    super.initState();
    semestersList = widget.preloadedSemesters.map(formatSemester).toList();
    if (semestersList.isNotEmpty) {
      currentSemester = semestersList[0];
    }
    _loadUserFuture = _loadInfo();
  }

  String formatSemester(String semester) {
    String year = semester.substring(0, 4);
    String season = getSeasonFromSemester(semester);
    return "$season $year";
  }

  Future<void> removeGPACourses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("savedCourses");
  }

  Future<void> _loadInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedSemester = prefs.getString('semester');

    // 현재 학기 목록에서 저장된 학기가 있는지 확인
    if (storedSemester != null && semestersList.contains(storedSemester)) {
      _selectSemester = formatSemester(storedSemester);
    } else {
      // 저장된 학기가 없거나 유효하지 않은 경우 기본 텍스트 설정
      _selectSemester = "Select Semester";
    }

    setState(() {
      _selectSemester = storedSemester;
    });
  }

  void _onSemesterChanged(String? value) {
    setState(() {
      _selectSemester = value;
      if (value != null) {
        _selectOriginalSemester = getOriginalSemester(value);
      }
    });
  }

  Future<void> _saveInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(
        'semester', _selectSemester ?? ''); // Use _selectSemester here
  }

  void _saveAndClose() {
    checkAccessToken();
    _saveInfo();
    Map<String, dynamic> userInfo = {
      'semester': _selectSemester, // Use _selectSemester here
    };
    Provider.of<SavedSemesterProvider>(context, listen: false)
        .setSelectedSemester(_selectSemester ?? '');

    widget.onboard ? null : Navigator.pop(context, userInfo);
  }

  @override
  Widget build(BuildContext context) {
    print("sdfsdf" + '$_selectSemester');
    print(widget.preloadedSemesters);
    var selectedCoursesData = Provider.of<CoursesProvider>(context);
    return FutureBuilder<void>(
      future: _loadUserFuture, // This should be your future that fetches data
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        // Check the state of the future
        if (snapshot.connectionState == ConnectionState.waiting) {
          // If the Future is still running, show a loading indicator
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // If we run into an error, display it to the user
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          var selectedCoursesData = Provider.of<CoursesProvider>(context);
          return ClipRRect(
            child: Scaffold(
              backgroundColor:
                  widget.onboard ? Colors.transparent : Colors.transparent,
              body: Padding(
                padding: const EdgeInsets.only(
                    top: 0, left: 10, right: 10, bottom: 25),
                child: Column(
                  children: [
                    Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: widget.onboard
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .background, //background
                        borderRadius: BorderRadius.all(
                            Radius.circular(30)), // 모서리를 둥글게 만듭니다.
                        // 필요하다면 여기에 그림자나 테두리 등을 추가할 수 있습니다.
                      ),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20), // 상단 왼쪽 모서리 둥글게
                                  topRight:
                                      Radius.circular(20), // 상단 오른쪽 모서리 둥글게
                                ),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  heightFactor:
                                      0.8, // 이미지의 상위 80%만 보여줍니다. 하단 20%는 잘립니다.
                                  child: SvgPicture.asset(
                                    'assets/icons/semester.svg',
                                    width: MediaQuery.of(context).size.width,
                                    // height 설정을 제거하여 전체 이미지 높이를 기준으로 잘립니다.
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    right: 10, bottom: 80),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (widget.onboard == false)
                                      Container(
                                        height: 30,
                                        width: 30,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          shape: BoxShape
                                              .circle, // Ensures the container is circular
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            FeatherIcons.x,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline,
                                            size: 20,
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
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Text(
                            "Select Semester",
                            style: TextStyle(
                              fontSize: 25,
                              color: Theme.of(context).colorScheme.outline,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "Selected Semester is used for\nCourse search, Schedule Creation, and sharing schedules with friends.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Container(
                            child: Form(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  PullDownButton(
                                    itemBuilder: (BuildContext context) {
                                      return semestersList
                                          .map((semester) => PullDownMenuItem(
                                                title: semester,
                                                onTap: () {
                                                  setState(() {
                                                    _selectSemester = semester;
                                                    String originalValue =
                                                        getOriginalSemester(
                                                            semester);
                                                    _selectOriginalSemester =
                                                        originalValue;
                                                    context
                                                            .read<
                                                                SemesterProvider>()
                                                            .originalSemester =
                                                        originalValue;
                                                  });
                                                },
                                              ))
                                          .toList();
                                    },
                                    buttonBuilder: (BuildContext context,
                                        Future<void> Function() showMenu) {
                                      return Container(
                                        decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .inversePrimary,
                                            borderRadius:
                                                BorderRadius.circular(15)),
                                        child: TextButton(
                                          onPressed: showMenu,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 50, vertical: 5),
                                            child: Text(
                                              _selectSemester ??
                                                  "Select Semester",
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .outline,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    scrollController: ScrollController(),
                                  )
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          widget.onboard
                              ? Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        widget.goBack();
                                        _saveAndClose();
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20),
                                        height: 55,
                                        width:
                                            MediaQuery.of(context).size.width /
                                                3,
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.redAccent,
                                                width: 2),
                                            color: Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(60)),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'BACK',
                                              style: TextStyle(
                                                  color: Colors.redAccent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        widget.gonext();
                                        _saveAndClose();
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20),
                                        height: 55,
                                        width:
                                            MediaQuery.of(context).size.width /
                                                3,
                                        decoration: BoxDecoration(
                                            color: Colors.blueAccent,
                                            borderRadius:
                                                BorderRadius.circular(60)),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'NEXT',
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
                                )
                              : GestureDetector(
                                  onTap: () {
                                    _saveAndClose();
                                    removeGPACourses();
                                    HapticFeedback.mediumImpact();
                                    Navigator.pushReplacement(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation,
                                                secondaryAnimation) =>
                                            HomePage(),
                                        transitionsBuilder: (context, animation,
                                            secondaryAnimation, child) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          );
                                        },
                                        transitionDuration: Duration(
                                            milliseconds:
                                                200), // Adjust the speed of the fade transition
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 30),
                                    height: 55,
                                    width:
                                        MediaQuery.of(context).size.width - 80,
                                    decoration: BoxDecoration(
                                        color: Colors.blueAccent,
                                        borderRadius:
                                            BorderRadius.circular(60)),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'DONE',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

class SemesterProvider with ChangeNotifier {
  String _originalSemester;

  SemesterProvider(String originalSemester)
      : _originalSemester = originalSemester;

  String get originalSemester => _originalSemester;

  set originalSemester(String value) {
    _originalSemester = value;
    notifyListeners();
  }
}

class SavedSemesterProvider with ChangeNotifier {
  String _selectedSemester;

  SavedSemesterProvider(this._selectedSemester);

  String get selectedSemester => _selectedSemester;

  void setSelectedSemester(String semester) {
    _selectedSemester = semester;
    notifyListeners();
  }
}
