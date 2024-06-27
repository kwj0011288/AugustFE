import 'package:august/components/home/button.dart';
import 'package:august/components/provider/courseprovider.dart';
import 'package:august/components/tile/onboardTile/sem_tile.dart';
import 'package:august/components/tile/onboardTile/univ_tile.dart';
import 'package:august/get_api/onboard/get_semester.dart';
import 'package:august/login/login.dart';
import 'package:august/pages/main/homepage.dart';
import 'package:cool_dropdown/models/cool_dropdown_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pull_down_button/pull_down_button.dart';
import "package:flutter_feather_icons/flutter_feather_icons.dart";
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:colorful_safe_area/colorful_safe_area.dart';

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

  // Helper function to extract season from semester string
  String extractSeason(String semester) {
    return semester
        .split(" ")[0]
        .toLowerCase(); // Assuming format "Season Year"
  }

// Adjusted determineColor function to use lowercase season names
  Color determineColor(String semester) {
    String season = extractSeason(semester);
    switch (season) {
      case "spring":
        return Color(0xFFffe6ea);
      case "summer":
        return Color(0xFFfff7e6);
      case "fall":
        return Color(0xFFffefe5);
      default:
        return Color(0xFFbac9f7); // Default for "winter" and any others
    }
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
          return Scaffold(
            body: ColorfulSafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,

                  // 필요하다면 여기에 그림자나 테두리 등을 추가할 수 있습니다.
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        if (widget.onboard == true)
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 20, top: 8, bottom: 8),
                            child: GestureDetector(
                              onTap: () {
                                widget.goBack();
                                _saveAndClose();
                              },
                              child: CircleAvatar(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.background,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 5),
                                  child: Center(
                                    child: Icon(
                                      Icons.arrow_back_ios,
                                      size: 15,
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Spacer(),
                        if (widget.onboard == false)
                          Padding(
                            padding: const EdgeInsets.only(
                                right: 20, top: 5, bottom: 10),
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                Navigator.pop(context);
                              },
                              child: CircleAvatar(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.background,
                                child: Center(
                                  child: Icon(
                                    FeatherIcons.x,
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (widget.onboard == true) SizedBox(height: 10),
                    Text(
                      widget.onboard ? "Select Semester" : "Change Semester",
                      style: TextStyle(
                        fontSize: 35,
                        color: Theme.of(context).colorScheme.outline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "Selected Semester is used for\nCourse search, and Schedule Creation.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Container(
                        child: Form(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: semestersList.map((semester) {
                              return SemesterTile(
                                semester: semester,
                                semesterIcon:
                                    "assets/season/${extractSeason(semester)}.svg",
                                backgroundColor: determineColor(semester),
                                tileColor: _selectSemester == semester
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary // Selected color
                                    : Theme.of(context)
                                        .colorScheme
                                        .primaryContainer, // Default color
                                isShadow: _selectSemester == semester,
                                onTap: () {
                                  setState(() {
                                    _selectSemester = semester;
                                    // Assuming getOriginalSemester is a function that fetches some additional details about the semester
                                    String originalValue =
                                        getOriginalSemester(semester);
                                    context
                                        .read<SemesterProvider>()
                                        .originalSemester = originalValue;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.only(
                left: 15,
                right: 15,
                bottom: 60,
              ),
              child: widget.onboard
                  ? GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        widget.gonext();
                        _saveAndClose();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        height: 60,
                        width: MediaQuery.of(context).size.width - 80,
                        decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
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
                    )
                  : GestureDetector(
                      onTap: () {
                        _saveAndClose();
                        HapticFeedback.mediumImpact();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        height: 55,
                        width: MediaQuery.of(context).size.width - 80,
                        decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(60)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
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
