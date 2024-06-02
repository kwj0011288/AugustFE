import 'dart:convert';
import 'dart:typed_data';
import 'package:august/get_api/onboard/get_semester.dart';
import 'package:august/get_api/wizard/schedule_get.dart';
import 'package:august/login/initialpage.dart';
import 'package:august/login/login.dart';
import 'package:august/onboard/major.dart';
import 'package:august/onboard/profile.dart';
import 'package:august/onboard/semester.dart';
import 'package:august/onboard/grade.dart';
import 'package:august/onboard/univ.dart';
import 'package:august/pages/gpa/gpa_page.dart';
import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pull_down_button/pull_down_button.dart';
import "package:flutter_feather_icons/flutter_feather_icons.dart";
import 'package:url_launcher/url_launcher.dart';

class Mypage extends StatefulWidget {
  final String selectedSemester;
  final ScrollController scrollController;
  final List<String> departments;
  final bool isFirst;
  const Mypage({
    Key? key,
    required this.selectedSemester,
    required this.scrollController,
    this.departments = const [],
    required this.isFirst,
  }) : super(key: key);

  State<Mypage> createState() => _MypageState();
}

class _MypageState extends State<Mypage> {
  int bottomIndex = 0;
  String? selectedValue;
  List<ScheduleList> _firstTimetableCourses = [];
  //info
  String _username = 'User';
  String _grade = 'Freshman';
  String _major = 'LTSC';
  String _schoolFullname = 'Unknown';
  String _schoolNickname = 'Unknown';
  String _semester = 'Unknown';
  Uint8List? profilePhoto;
  String _email = 'Welcome to August';
  late Future<void> _loadUserFuture;
  Map<int, String> selectedGrades = {};

  String formatSemester(String semester) {
    String year = semester.substring(0, 4);
    String season = getSeasonFromSemester(semester);
    return "$season $year";
  }

  void initState() {
    super.initState();
    _loadUserFuture = loadUserInfo();
    _loadUserFuture = loadUserInfo().then((_) {
      // Load the profile photo after the user info is loaded
      loadProfilePhoto();
    });
    loadFirstTimetable();
    for (int i = 0; i < _firstTimetableCourses.length; i++) {
      selectedGrades[i] = 'GPA'; // Default value for each course
    }
  }

  Future<void> loadProfilePhoto() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? base64Image = prefs.getString('contactPhoto');
    if (base64Image != null) {
      setState(() {
        profilePhoto = base64Decode(base64Image);
      });
    }
  }

  Future<void> saveSelectedGrades() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Convert the map to have String keys
    Map<String, String> stringKeyMap =
        selectedGrades.map((key, value) => MapEntry(key.toString(), value));
    String gradesJson = jsonEncode(stringKeyMap);
    bool saveResult = await prefs.setString('selectedGrades', gradesJson);

    // 저장 성공 여부 확인
    if (saveResult) {
      print("Grades saved successfully.");
    } else {
      print("Failed to save grades.");
    }
  }

  Future<void> loadFirstTimetable() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('timetable');
    String? gradesJson =
        prefs.getString('selectedGrades'); // Fetch the saved grades JSON string

    if (jsonString != null) {
      try {
        List<dynamic> decodedJson = jsonDecode(jsonString);
        if (decodedJson.isNotEmpty) {
          List<dynamic> firstTimetableDataList = decodedJson[0];
          List<ScheduleList> firstTimetableCourses = firstTimetableDataList
              .map((e) => ScheduleList.fromJson(e as Map<String, dynamic>))
              .toList();

          setState(() {
            _firstTimetableCourses = firstTimetableCourses;
          });
        }
      } catch (e) {
        print("Error loading timetable: $e");
      }
    } else {
      print("No timetable data found in SharedPreferences.");
    }

    if (gradesJson != null) {
      try {
        Map<String, dynamic> gradesMap = jsonDecode(gradesJson);
        // Convert the map with String keys back to a map with int keys
        setState(() {
          selectedGrades =
              gradesMap.map((key, value) => MapEntry(int.parse(key), value));
        });
      } catch (e) {
        print("Error loading grades: $e");
      }
    }
  }

  void _navigateToPage() async {
    var result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.pop(context);
          },
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            maxChildSize: 1,
            minChildSize: 0.7,
            builder: (BuildContext context, ScrollController scrollController) {
              var preloadedSemesters =
                  Provider.of<SemestersProvider>(context, listen: false)
                      .semesters;
              return GestureDetector(
                onTap: () {},
                // child: ProfileEditPage(
                //   preloadedSemesters:
                //       preloadedSemesters, // 리스트로 다시 감싸지 않고 바로 전달
                // ),
              );
            },
          ),
        );
      },
    );
    if (result != null) {
      setState(() {
        // 반환된 데이터를 사용하여 상태를 업데이트
        _username = result['name'] ?? _username;
        _grade = result['grade'] ?? _grade;
        _major = result['major'] ?? _major;
        _schoolFullname = result['fullname'] ?? _schoolFullname;
        _schoolNickname = result['nickname'] ?? _schoolNickname;
        _semester = result['semester'] ?? _semester;
      });

      saveUserInfo(); // 상태를 업데이트한 후에 사용자 정보를 저장합니다.
    }
  }

  void _navigateToPageProfile() async {
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
                child: NamePage(
                    onboard: false,
                    onTap: () {},
                    onPhotoUpdated: (photo) {
                      if (photo != null) {
                        setState(() {
                          profilePhoto = photo;
                          // You might also want to save the photo to SharedPreferences here
                        });
                      }
                    }),
              );
            },
          ),
        );
      },
    );
    if (result != null) {
      setState(() {
        // 반환된 데이터를 사용하여 상태를 업데이트
        _username = result['name'] ?? _username;
      });

      saveUserInfo(); // 상태를 업데이트한 후에 사용자 정보를 저장합니다.
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
    if (result != null) {
      setState(() {
        // 반환된 데이터를 사용하여 상태를 업데이트
        _semester = result['semester'] ?? _semester;
      });

      saveUserInfo(); // 상태를 업데이트한 후에 사용자 정보를 저장합니다.
    }
  }

  void _navigateToPageMajor() async {
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
                child: MajorPage(
                  onboard: false,
                  goBack: () {},
                  gonext: () {},
                  preloadedDepartments: widget.departments,
                ),
              );
            },
          ),
        );
      },
    );
    if (result != null) {
      setState(() {
        _major = result['major'] ?? _major;
      });

      saveUserInfo(); // 상태를 업데이트한 후에 사용자 정보를 저장합니다.
    }
  }

  void _navigateToPageUniv() async {
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
                child: UnivPage(
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
    if (result != null) {
      setState(() {
        // 반환된 데이터를 사용하여 상태를 업데이트

        _grade = result['grade'] ?? _grade;

        _schoolFullname = result['fullname'] ?? _schoolFullname;
        _schoolNickname = result['nickname'] ?? _schoolNickname;
      });

      saveUserInfo(); // 상태를 업데이트한 후에 사용자 정보를 저장합니다.
    }
  }

  void _navigateToPageGrade() async {
    var result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
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
                child: GradePage(
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
    if (result != null) {
      setState(() {
        // 반환된 데이터를 사용하여 상태를 업데이트

        _grade = result['grade'] ?? _grade;

        _schoolFullname = result['fullname'] ?? _schoolFullname;
        _schoolNickname = result['nickname'] ?? _schoolNickname;
      });

      saveUserInfo(); // 상태를 업데이트한 후에 사용자 정보를 저장합니다.
    }
  }

  void _launchURL() async {
    const url = 'https://forms.gle/2ytdRmXgFps7pK567';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> saveUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', _username);
    await prefs.setString('grade', _grade);
    await prefs.setString('major', _major);
    await prefs.setString('fullname', _schoolFullname);
    await prefs.setString('nickname', _schoolNickname);
    await prefs.setString('semester', _semester);
    await prefs.setString('userEmail', _email); // Save the email

    // Check if the data is saved correctly
    print(prefs.getString('name')); // It should print the username
    await loadUserInfo();
  }

  Future<void> loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('name') ?? 'User'; //이거랑
    _grade = prefs.getString('grade') ?? 'Freshman'; // 이거랑
    _major = prefs.getString('major') ?? 'LTSC'; //이거랑
    _schoolFullname = prefs.getString('fullname') ?? 'Unknown'; //이거랑
    _schoolNickname = prefs.getString('nickname') ?? 'Unknown'; //이거랑
    _email = prefs.getString('userEmail') ?? _email;
    // Fetch the semester and convert it
    String? storedSemester = prefs.getString('semester');
    if (storedSemester != null) {
      try {
        _semester = (storedSemester);
      } catch (e) {
        _semester = '202008'; // Use a default value in case of an exception
      }
    } else {
      _semester = '202008'; // Use a default value if there's no stored value
    }

    setState(() {}); // Update the UI with the new values
  }

  double calculateTextWidth(
      String text, TextStyle style, BuildContext context) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);

    return textPainter.size.width;
  }

  Widget buildButton(String text, Color buttonColor, final VoidCallback onTap) {
    TextStyle buttonTextStyle = TextStyle(
      // Define your text style here
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    double textWidth = calculateTextWidth(text, buttonTextStyle, context);
    double buttonWidth = textWidth + 20; // Add some padding to the text width

    return Container(
      width: buttonWidth,
      height: 30,
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 5),
                Center(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_right, color: Colors.black, size: 18)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget SignoutButton(
      String text, Color buttonColor, final VoidCallback onTap) {
    TextStyle buttonTextStyle = TextStyle(
      // Define your text style here
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    double textWidth = calculateTextWidth(text, buttonTextStyle, context);
    double buttonWidth = textWidth + 45; // Add some padding to the text width

    return Container(
      width: buttonWidth,
      height: 40,
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
                style: TextStyle(
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

  int getTotalCredits() {
    int totalCredits = 0;
    for (var course in _firstTimetableCourses) {
      totalCredits += course.credits ?? 0;
    }
    return totalCredits;
  }

  int getCourseCount() {
    return _firstTimetableCourses.length;
  }

  double getNumericGrade(String grade) {
    Map<String, double> gradeToPoint = {
      'A+': 4.0,
      'A': 4.0,
      'A-': 3.7,
      'B+': 3.3,
      'B': 3.0,
      'B-': 2.7,
      'C+': 2.3,
      'C': 2.0,
      'C-': 1.7,
      'D+': 1.3,
      'D': 1.0,
      'F': 0.0,
    };

    return gradeToPoint[grade] ?? 0.0; // Returns 0.0 if grade is not found
  }

  double calculateTotalGPA() {
    double totalGradePoints = 0.0;
    int totalCredits = 0;

    for (int i = 0; i < _firstTimetableCourses.length; i++) {
      String grade = selectedGrades[i] ?? "-";
      double numericGrade = getNumericGrade(grade);
      int courseCredits = _firstTimetableCourses[i].credits ?? 0;

      totalGradePoints += numericGrade * courseCredits;
      totalCredits += courseCredits;
    }

    if (totalCredits == 0) {
      return 0.0; // Avoid division by zero
    }

    return totalGradePoints / totalCredits;
  }

  @override
  Widget build(BuildContext context) {
    //print("for mepage" + _semester);
    return FutureBuilder(
      future: _loadUserFuture,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator()); // 로딩 인디케이터 표시
        } else if (snapshot.hasError) {
          return Center(child: Text('An error occurred.')); // 에러 메시지 표시
        } else {
          return ClipRRect(
            child: Scaffold(
              backgroundColor: Theme.of(context).colorScheme.background,
              appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.background,
                forceMaterialTransparency: true,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 15),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              _navigateToPageProfile();
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
                          SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _navigateToPageProfile();
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment
                                  .center, // Center texts vertically
                              crossAxisAlignment: CrossAxisAlignment
                                  .start, // Align texts to the start
                              children: [
                                Text(
                                  '$_username',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline),
                                ), // Text Style if needed
                                Text(
                                  "$_email",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey),
                                ), // Text Style if needed
                              ],
                            ),
                          ),
                          Spacer(),
                        ],
                      ),
                      SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(left: 0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Consumer<SavedSemesterProvider>(
                                builder: (context, semesterProvider, child) {
                                  return buildButton(
                                    semesterProvider.selectedSemester.isNotEmpty
                                        ? (semesterProvider.selectedSemester)
                                        : "Select Semester",
                                    Color(0xFFe5fff9),
                                    () {
                                      HapticFeedback.mediumImpact();
                                      _navigateToPageSemester();
                                    },
                                  );
                                },
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              buildButton((('$_grade')), Color(0xFFffe6ea), () {
                                HapticFeedback.mediumImpact();
                                _navigateToPageGrade();
                              }),
                              SizedBox(
                                width: 10,
                              ),
                              buildButton(
                                '$_major',
                                Color(0xFFe3ecff),
                                () {
                                  HapticFeedback.mediumImpact();
                                  _navigateToPageMajor();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                leadingWidth: 500,
                toolbarHeight: 110,
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 15, bottom: 40),
                    child: Container(
                      height: 35,
                      width: 35,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape
                            .circle, // Ensures the container is circular
                      ),
                      child: IconButton(
                        icon: Icon(
                          FeatherIcons.x,
                          color: Theme.of(context).colorScheme.outline,
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
                  ),
                ],
              ),
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                child: ColorfulSafeArea(
                  bottomColor: Colors.white.withOpacity(0),
                  overflowRules: OverflowRules.only(bottom: true),
                  child: SingleChildScrollView(
                    controller: widget.scrollController,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 5,
                        ),
                        Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 20),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).colorScheme.background,
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: Colors.grey.shade600),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Theme.of(context).colorScheme.shadow,
                                      blurRadius: 10,
                                      offset: Offset(6, 4),
                                    ),
                                    BoxShadow(
                                      color:
                                          Theme.of(context).colorScheme.shadow,
                                      blurRadius: 10,
                                      offset: Offset(-2, 0),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "About Me",
                                        style: TextStyle(
                                          fontSize: 25,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(
                                        height: 15,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              HapticFeedback.mediumImpact();
                                              _navigateToPageUniv();
                                            },
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "School",
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.grey,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 3,
                                                ),
                                                Row(
                                                  children: [
                                                    Text(
                                                      "$_schoolNickname",
                                                      style: TextStyle(
                                                        fontSize: 25,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .outline,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Icon(Icons
                                                        .keyboard_arrow_right),
                                                  ],
                                                ),
                                                Text(
                                                  "$_schoolFullname",
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.grey,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Spacer(),
                                          GestureDetector(
                                            onTap: () {
                                              HapticFeedback.mediumImpact();
                                              Navigator.push(
                                                context,
                                                PageRouteBuilder(
                                                  pageBuilder: (context,
                                                          animation,
                                                          secondaryAnimation) =>
                                                      GPAPage(
                                                          semester: _semester!),
                                                  transitionsBuilder: (context,
                                                      animation,
                                                      secondaryAnimation,
                                                      child) {
                                                    var begin =
                                                        Offset(0.0, 1.0);
                                                    var end = Offset.zero;
                                                    var curve = Curves.ease;

                                                    var tween = Tween(
                                                            begin: begin,
                                                            end: end)
                                                        .chain(CurveTween(
                                                            curve: curve));

                                                    return SlideTransition(
                                                      position: animation
                                                          .drive(tween),
                                                      child: child,
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Credits",
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.grey,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 3,
                                                ),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.school_outlined,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .outline,
                                                      size: 22,
                                                    ),
                                                    SizedBox(width: 5),
                                                    Text(
                                                      "${getTotalCredits()}",
                                                      style: TextStyle(
                                                        fontSize: 25,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .outline,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  " ",
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.grey,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 30,
                                      ),
                                      Row(
                                        children: [
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Friends",
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(
                                                height: 3,
                                              ),
                                              Row(
                                                children: [
                                                  Icon(Icons.people),
                                                  SizedBox(width: 5),
                                                  Text(
                                                    "0",
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .outline,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Spacer(),
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Courses",
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(
                                                height: 3,
                                              ),
                                              Row(
                                                children: [
                                                  Icon(
                                                    FeatherIcons.archive,
                                                    size: 20,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .outline,
                                                  ),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    "${getCourseCount()}",
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .outline,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Spacer(),
                                          GestureDetector(
                                            onTap: () {
                                              HapticFeedback.mediumImpact();
                                              Navigator.push(
                                                context,
                                                PageRouteBuilder(
                                                  pageBuilder: (context,
                                                          animation,
                                                          secondaryAnimation) =>
                                                      GPAPage(
                                                          semester: _semester!),
                                                  transitionsBuilder: (context,
                                                      animation,
                                                      secondaryAnimation,
                                                      child) {
                                                    var begin =
                                                        Offset(0.0, 1.0);
                                                    var end = Offset.zero;
                                                    var curve = Curves.ease;

                                                    var tween = Tween(
                                                            begin: begin,
                                                            end: end)
                                                        .chain(CurveTween(
                                                            curve: curve));

                                                    return SlideTransition(
                                                      position: animation
                                                          .drive(tween),
                                                      child: child,
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "GPA",
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.grey,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 3,
                                                ),
                                                Row(
                                                  children: [
                                                    Text(
                                                      "${calculateTotalGPA().toStringAsFixed(2)}",
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .outline,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: GestureDetector(
                                onTap: () {},
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 20),
                                  decoration: BoxDecoration(
                                    color: Color.fromARGB(255, 9, 9, 45),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color:
                                            Color.fromARGB(255, 170, 169, 255)),
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
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              alignment: Alignment.center,
                                              height: 30,
                                              width: 75,
                                              decoration: BoxDecoration(
                                                color: Color(0xFF191975),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                "Premium",
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Color.fromARGB(
                                                      255, 170, 169, 255),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 20),
                                            Text(
                                              "Complete your school life",
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Color.fromARGB(
                                                    255, 170, 169, 255),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        Text(
                                          "Upgrade to remove Ad's & Invite more friends",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Color.fromARGB(
                                                255, 170, 169, 255),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 0, top: 0),
                              child: Container(
                                width: 300.0, // 원하는 크기 설정
                                height: 50.0, // 원하는 크기 설정
                                decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(30)),
                                child: Center(
                                    child: TextButton(
                                  child: Text(
                                    'Please send us Feedback',
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: _launchURL,
                                )),
                              ),
                            ),
                            SizedBox(height: 20),
                            SignoutButton(
                              'Sign out',
                              Color.fromARGB(255, 243, 154, 168),
                              () async {
                                await logoutUser();

                                // 로그아웃 후 InitialPage로 이동
                                Navigator.pushReplacement(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) => InitialPage(
                                      departments: [],
                                      preloadedSemesters: [],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
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

class SemestersProvider with ChangeNotifier {
  List<String> _semesters = [];

  SemestersProvider(this._semesters);

  List<String> get semesters => _semesters;

  set semesters(List<String> value) {
    _semesters = value;
    notifyListeners();
  }
}
