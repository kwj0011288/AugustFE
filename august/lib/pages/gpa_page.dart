import 'dart:convert';
import 'dart:ui';
import 'package:august/components/timetable.dart';
import 'package:august/const/dark_theme.dart';
import 'package:august/const/light_theme.dart';
import 'package:august/const/tile_color.dart';
import 'package:august/get_api/schedule.dart';
import 'package:august/onboard/semester.dart';
import 'package:august/pages/grade_cal.dart';
import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import "package:flutter_feather_icons/flutter_feather_icons.dart";
import 'package:flutter/material.dart' hide ModalBottomSheetRoute;

class GPAPage extends StatefulWidget {
  final String semester;
  List<TimeTables>? firstTimeTable = [];

  GPAPage({Key? key, required this.semester, this.firstTimeTable})
      : super(key: key);

  @override
  State<GPAPage> createState() => _GPAPageState();
}

class Course {
  String name;
  int credits;
  String grade;
  String letterGrade;

  Course({
    required this.name,
    required this.credits,
    required this.grade,
    this.letterGrade = '??',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'credits': credits,
        'grade': grade,
        'letterGrade': letterGrade,
      };

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        name: json['name'],
        credits: json['credits'],
        grade: json['grade'],
        letterGrade: json['letterGrade'] ?? '??',
      );
}

class _GPAPageState extends State<GPAPage> {
  List<Course> courses = [];
  int _totalCredits = 0; // 총 학점을 저장할 변수
  double _newGPA = 0.0; // 새로운 GPA를 저장할 변수
  int totalLength = 0;

  @override
  void initState() {
    super.initState();
    if (widget.firstTimeTable != null && widget.firstTimeTable!.isNotEmpty) {
      for (var timetable in widget.firstTimeTable!) {
        for (var sectionList in timetable.coursesData) {
          for (var section in sectionList) {
            courses.add(Course(
              name: section.sectionCode!
                  .substring(0, section.sectionCode!.indexOf("-")),
              credits: section.credits!,
              grade: "",
            ));
          }
        }
      }
    }
    loadCourses();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> addCourse() async {
    // Controllers for the form fields
    TextEditingController nameController = TextEditingController();
    TextEditingController creditsController = TextEditingController();

    // Show modal and wait for the result
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return courseFormModal(context, nameController, creditsController);
      },
    );

    if (result != null && result['name'].isNotEmpty) {
      setState(() {
        courses.add(Course(
          name: result['name'],
          credits: int.tryParse(result['credits']) ??
              0, // Fallback to 0 if parsing fails
          grade: "",
        ));
        saveCourses();
      });
    }
  }

  Widget courseFormModal(
      BuildContext context,
      TextEditingController nameController,
      TextEditingController creditsController) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        color: Theme.of(context).colorScheme.background,
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Text(
              "Add Course",
              style: TextStyle(
                fontSize: 25,
                color: Theme.of(context).colorScheme.outline,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            CupertinoTextField(
              autofocus: true,
              controller: nameController,
              placeholder: "Name",
              placeholderStyle: TextStyle(
                color: Theme.of(context).colorScheme.outline,
              ),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.outline,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inversePrimary,
                borderRadius: BorderRadius.circular(15),
              ),
              cursorColor: Theme.of(context).colorScheme.outline,
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
            ),
            SizedBox(height: 15),
            CupertinoTextField(
              controller: creditsController,
              placeholder: "Credits",
              placeholderStyle: TextStyle(
                color: Theme.of(context).colorScheme.outline,
              ),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.outline,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inversePrimary,
                borderRadius: BorderRadius.circular(15),
              ),
              cursorColor: Theme.of(context).colorScheme.outline,
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')), // 숫자만 허용
                LengthLimitingTextInputFormatter(1), // 최대 길이를 3으로 제한
              ],
            ),
            SizedBox(height: 15),
            GestureDetector(
              onTap: () {
                // Collecting input data and popping the modal with result
                Navigator.of(context).pop({
                  'name': nameController.text,
                  'credits': creditsController.text,
                });
              },
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(15)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Submit',
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
        ),
      ),
    );
  }

  Future<void> saveCourses() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> jsonCourses =
        courses.map((course) => json.encode(course.toJson())).toList();
    await prefs.setStringList('savedCourses', jsonCourses);
  }

  Future<void> loadCourses() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> jsonCourses = prefs.getStringList('savedCourses') ?? [];
    if (jsonCourses.isNotEmpty) {
      setState(() {
        courses = jsonCourses
            .map((jsonCourse) => Course.fromJson(json.decode(jsonCourse)))
            .toList();
      });
    }
  }

  // Convert letter grades to numeric values
  double gradeToNumber(String letterGrade) {
    switch (letterGrade) {
      case 'A+':
        return 4.0;
      case 'A':
        return 4.0;
      case 'A-':
        return 3.7;
      case 'B+':
        return 3.3;
      case 'B':
        return 3.0;
      case 'B-':
        return 2.7;
      case 'C+':
        return 2.3;
      case 'C':
        return 2.0;
      case 'C-':
        return 1.7;
      case 'D+':
        return 1.3;
      case 'D':
        return 1.0;
      case 'D-':
        return 0.7;
      case 'F':
        return 0.0;
      default:
        return 0.0; // Handle unknown grades
    }
  }

// Calculate GPA
  void calculateGPA() {
    double totalPoints = 0;
    int totalCredits = 0;

    for (Course course in courses) {
      if (course.letterGrade != '??') {
        double courseGrade = gradeToNumber(course.letterGrade);
        totalPoints += courseGrade * course.credits;
        totalCredits += course.credits;
      }
    }

    if (totalCredits != 0) {
      setState(() {
        _newGPA = totalPoints / totalCredits;
        _totalCredits = totalCredits;
        // Format GPA to two decimal places
        _newGPA = double.parse(_newGPA.toStringAsFixed(2));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    calculateGPA();
    _totalCredits = courses.fold(0, (sum, course) => sum + course.credits);
    final theme = Theme.of(context);
    List<Color> tileColors =
        theme.brightness == Brightness.dark ? tileColorsDark : tileColorsLight;
    totalLength = courses.isEmpty ? 1 : courses.length + 1;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: ColorfulSafeArea(
          bottomColor: Colors.white.withOpacity(0),
          overflowRules: OverflowRules.only(bottom: true),
          child: Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GPA Calculator',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        Consumer<SavedSemesterProvider>(
                          builder: (context, semesterProvider, child) {
                            return Text(
                              '${semesterProvider.selectedSemester}',
                              style:
                                  TextStyle(fontSize: 15, color: Colors.grey),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 15, right: 10, top: 15, bottom: 20),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                      },
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.background,
                        child: Center(
                          child: Icon(
                            FeatherIcons.x,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Consumer<SavedSemesterProvider>(
                          builder: (context, semesterProvider, child) {
                            return Text(
                              '${(totalLength - 1).toString()} Courses',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            );
                          },
                        ),
                        Spacer(),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: GridView.builder(
                    itemCount: courses.isEmpty ? 1 : courses.length + 1,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width >
                              MediaQuery.of(context).size.height
                          ? 3
                          : 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.0,
                    ),
                    itemBuilder: (context, idx) {
                      if (idx == courses.length) {
                        return GestureDetector(
                          onTap: () {
                            addCourse();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Icon(Icons.add,
                                  color: Theme.of(context).colorScheme.outline,
                                  size: 40),
                            ),
                          ),
                        );
                      }
                      Course course = courses[idx];
                      return GestureDetector(
                        onTap: () async {
                          var letterGrade = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GradeCalcPage(index: idx),
                            ),
                          );

                          if (letterGrade != null) {
                            setState(() {
                              courses[idx].letterGrade = letterGrade;
                              saveCourses();
                            });
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: tileColors[idx % tileColors.length],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(10),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Center(
                                        child: Text(
                                          course.name,
                                          style: TextStyle(
                                            fontSize: 25,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 15,
                                        color: Colors.black,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: makeDarker(
                                        tileColors[idx % tileColors.length],
                                        0.2),
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Text(
                                        'Credits: ${course.credits}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: "Apple",
                                        ),
                                      ),
                                      Text(
                                        'GPA: ${courses[idx].letterGrade}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: "Apple",
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        child: Container(
          margin:
              const EdgeInsets.only(left: 15, right: 15, bottom: 30, top: 10),
          height: 80,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Total Credit: ',
                  style: TextStyle(
                    fontSize: 25,
                    color: Theme.of(context).colorScheme.outline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$_totalCredits',
                  style: TextStyle(
                    fontSize: 25,
                    color: Theme.of(context).colorScheme.outline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Text(
                  'GPA: ',
                  style: TextStyle(
                    fontSize: 25,
                    color: Theme.of(context).colorScheme.outline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$_newGPA',
                  style: TextStyle(
                    fontSize: 25,
                    color: Theme.of(context).colorScheme.outline,
                    fontWeight: FontWeight.bold,
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
