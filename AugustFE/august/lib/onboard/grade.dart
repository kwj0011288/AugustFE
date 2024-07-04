import 'package:august/components/home/button.dart';
import 'package:august/components/provider/courseprovider.dart';
import 'package:august/components/tile/onboardTile/grade_tile.dart';
import 'package:august/get_api/onboard/get_semester.dart';
import 'package:august/login/login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pull_down_button/pull_down_button.dart';
import "package:flutter_feather_icons/flutter_feather_icons.dart";
import 'package:colorful_safe_area/colorful_safe_area.dart';

class GradePage extends StatefulWidget {
  final bool onboard;
  final VoidCallback goBack;
  final VoidCallback gonext;
  GradePage({
    super.key,
    required this.onboard,
    required this.goBack,
    required this.gonext,
  });

  @override
  _GradePageState createState() => _GradePageState();
}

class _GradePageState extends State<GradePage> {
  String? _selectGrade;
  String? _sendGrade;

  late Future<void> _loadUserFuture;

  late List<String> semestersList = [];
  late String currentSemester = '';

  @override
  void dispose() {
    super.dispose();
  }

// initState에서 _loadInfo 호출
  @override
  void initState() {
    super.initState();

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

  Future<void> _loadInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? semester = prefs.getString('semester');
    // Check if the semester value is in the semestersList
    if (!semestersList.contains(semester)) {
      // If not, set it to the first value of the semestersList
      semester = semestersList.isNotEmpty ? semestersList[0] : null;
    }
    setState(() {
      _selectGrade = (prefs.getString('grade') ?? null);
    });
  }

  Future<void> _saveInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setString('grade', _selectGrade ?? ''); // Provide a default value
  }

// 'Done' 버튼이 클릭될 때 _saveInfo 호출
  Future<void> _saveAndClose() async {
    checkAccessToken();
    await _saveInfo();
    Map<String, dynamic> userInfo = {
      'grade': _selectGrade,
    };

// 학년에 따라 _sendGrade 설정
    switch (_selectGrade) {
      case 'Freshman':
        _sendGrade = 'FR';
        break;
      case 'Sophomore':
        _sendGrade = 'SO';
        break;
      case 'Junior':
        _sendGrade = 'JR';
        break;
      case 'Senior':
        _sendGrade = 'SR';
        break;
      default:
        _sendGrade = ''; // 기본값 또는 오류 처리
    }
    widget.onboard ? null : Navigator.pop(context, userInfo);

    int? userPk = await fetchUserPk();

    if (userPk == null) {
      print("Failed to fetch userPk");
      return;
    }

    if (_selectGrade!.isNotEmpty) {
      // updateInstitution을 백그라운드에서 호출
      updateGrade(userPk, _sendGrade!).then((_) {
        print('Grade updated successfully');
      }).catchError((error) {
        print('Failed to update Grade: $error');
      });
    }
  }

  void _oneGradeChanged(String? value) {
    setState(() {
      _selectGrade = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('Current selectGrade value: $_selectGrade');
    List<String> grades = ['Freshman', 'Sophomore', 'Junior', 'Senior'];
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
                ),
                child: Center(
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
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline,
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
                        widget.onboard ? "Select Grade" : "Senior Yet?",
                        style: TextStyle(
                          fontSize: 35,
                          color: Theme.of(context).colorScheme.outline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        "How much longer until I finish school?\nChoose your grade to get started",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 40),
                      Container(
                        child: Form(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: grades.map((grade) {
                              return GradeTile(
                                grade: grade,
                                tileColor: _selectGrade == grade
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary // Selected color
                                    : Theme.of(context)
                                        .colorScheme
                                        .primaryContainer, // Non-selected color
                                isShadow: _selectGrade == grade,
                                onTap: () {
                                  setState(() {
                                    _selectGrade = grade;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
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
