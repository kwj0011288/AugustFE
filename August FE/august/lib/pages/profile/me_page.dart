import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:august/components/mepage/color_box.dart';
import 'package:august/components/mepage/color_picker.dart';
import 'package:august/components/mepage/course_color.dart';
import 'package:august/components/mepage/gpa_graph.dart';
import 'package:august/components/mepage/info_box.dart';
import 'package:august/components/mepage/premium.dart';
import 'package:august/components/profile/profile.dart';
import 'package:august/provider/course_color_provider.dart';
import 'package:august/provider/friends_provider.dart';
import 'package:august/get_api/gpa/gpa_courses.dart';
import 'package:august/get_api/onboard/get_semester.dart';
import 'package:august/get_api/onboard/get_univ.dart';
import 'package:august/get_api/wizard/schedule_get.dart';
import 'package:august/login/initialpage.dart';
import 'package:august/login/login.dart';
import 'package:august/onboard/major.dart';
import 'package:august/onboard/profile.dart';
import 'package:august/onboard/semester.dart';
import 'package:august/onboard/grade.dart';
import 'package:august/onboard/univ.dart';
import 'package:august/pages/gpa/gpa_page.dart';
import 'package:august/pages/main/homepage.dart';
import 'package:august/pages/profile/change_color_page.dart';
import 'package:august/provider/semester_provider.dart';
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
  const Mypage({
    Key? key,
  }) : super(key: key);

  State<Mypage> createState() => _MypageState();
}

class _MypageState extends State<Mypage> {
  int bottomIndex = 0;

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
  bool isJustGPA = true;
  bool isJustCredit = true;
  List<TotalGPA> totalSemester = [];

  void initState() {
    super.initState();
    //info and image
    _loadUserFuture = loadUserInfo();
    _loadUserFuture = loadUserInfo().then((_) {
      // Load the profile photo after the user info is loaded
      loadProfilePhoto();
    });

    //gpa
    loadTotalGPA().then((loadedGPAList) {
      setState(() {
        totalSemester = loadedGPAList;
      });
    });
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

  Future<void> loadProfilePhoto() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? base64Image = prefs.getString('contactPhoto');
    if (base64Image != null) {
      setState(() {
        profilePhoto = base64Decode(base64Image);
      });
    }
  }

  void _navigateToPageProfile() async {
    var result = await Navigator.push<Map<String, dynamic>>(
      context,
      CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (context) {
            return NamePage(
              onboard: false,
              onTap: () {},
              onPhotoUpdated: (photo) {
                if (photo != null) {
                  setState(() {
                    profilePhoto = photo;
                  });
                }
              },
            );
          }),
    );
    if (result != null) {
      setState(() {
        _username = result['name'] ?? _username;
      });
      saveUserInfo(); // Save updated user info after state updates
    }
  }

  void _navigateToPageSemester() async {
    var result = await Navigator.push<Map<String, dynamic>>(
      context,
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) {
          return SemesterPage(
            onboard: false,
            goBack: () {},
            gonext: () {},
          );
        },
      ),
    );

    saveUserInfo(); // 상태를 업데이트한 후에 사용자 정보를 저장합니다.
  }

  void _navigateToPageMajor() async {
    var result = await Navigator.push<Map<String, dynamic>>(
      context,
      CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (context) {
            return MajorPage(
              onboard: false,
              goBack: () {},
              gonext: () {},
            );
          }),
    );

    if (result != null) {
      setState(() {
        _major = result['major'] ?? _major;
      });

      saveUserInfo(); // 상태를 업데이트한 후에 사용자 정보를 저장합니다.
    }
  }

  void _navigateToPageUniv() async {
    var result = await Navigator.push<Map<String, dynamic>>(
      context,
      CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (context) {
            return UnivPage(
              onboard: false,
              goBack: () {},
              gonext: () {},
            );
          }),
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
    var result = await Navigator.push<Map<String, dynamic>>(
      context,
      CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (context) {
            return GradePage(
              onboard: false,
              goBack: () {},
              gonext: () {},
            );
          }),
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

    // Define a helper function to check if all required fields are not null.
    bool allFieldsLoaded() {
      return prefs.getString('name') != null &&
          prefs.getString('grade') != null &&
          prefs.getString('major') != null &&
          prefs.getString('fullname') != null &&
          prefs.getString('nickname') != null &&
          prefs.getString('userEmail') != null;
    }

    // Wait for all fields to be loaded.
    while (!allFieldsLoaded()) {
      await Future.delayed(
          Duration(seconds: 1)); // Wait for 1 second before checking again.
      prefs
          .reload(); // Optionally reload preferences if they could be updated externally.
    }

    // Once all fields are loaded, assign them.
    _username = prefs.getString('name') ?? 'User';
    _grade = prefs.getString('grade') ?? 'Freshman';
    _major = prefs.getString('major') ?? 'LTSC';
    _schoolFullname = prefs.getString('fullname') ?? 'Unknown';
    _schoolNickname = prefs.getString('nickname') ?? 'Unknown';
    _email = prefs.getString('userEmail') ?? _email;

    // Update the UI if necessary.
    setState(() {});
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

  Future<List<TotalGPA>> loadTotalGPA() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> gpaStringList = prefs.getStringList('totalGPA') ?? [];
    List<TotalGPA> totalGPAList = gpaStringList
        .map((gpaString) => TotalGPA.fromJson(jsonDecode(gpaString)))
        .toList();
    return totalGPAList;
  }

  @override
  Widget build(BuildContext context) {
    int friendsCount = Provider.of<FriendsProvider>(context).friendsCount;
    var colorProvider = Provider.of<CourseColorProvider>(context);
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
                                checkAccessToken();
                                HapticFeedback.lightImpact();
                                _navigateToPageProfile();
                              },
                              child: ProfileWidget(
                                isBottomBar: false,
                              )),
                          SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              checkAccessToken();
                              HapticFeedback.lightImpact();
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
                              Consumer<SemesterProvider>(
                                builder: (context, semesterProvider, child) {
                                  return buildButton(
                                    formatSemester(semesterProvider.semester),
                                    Color(0xFFe5fff9),
                                    () {
                                      checkAccessToken();
                                      HapticFeedback.lightImpact();
                                      _navigateToPageSemester();
                                    },
                                  );
                                },
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              buildButton((('$_grade')), Color(0xFFffe6ea), () {
                                checkAccessToken();
                                HapticFeedback.lightImpact();
                                _navigateToPageGrade();
                              }),
                              SizedBox(
                                width: 10,
                              ),
                              buildButton(
                                '$_major',
                                Color(0xFFe3ecff),
                                () {
                                  checkAccessToken();
                                  HapticFeedback.lightImpact();
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
              ),
              body: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: ColorfulSafeArea(
                  bottomColor: Colors.white.withOpacity(0),
                  overflowRules: OverflowRules.only(bottom: true),
                  child: SingleChildScrollView(
                    controller: ScrollController(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "About Me",
                          style: TextStyle(
                            fontSize: 25,
                            color: Theme.of(context).colorScheme.outline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SingleChildScrollView(
                          controller: ScrollController(),
                          scrollDirection: Axis.horizontal,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                            child: Row(
                              children: [
                                InfoWidget(
                                  onTap: () {
                                    checkAccessToken();
                                    HapticFeedback.lightImpact();
                                    _navigateToPageUniv();
                                  },
                                  isSchool: true,
                                  isFrirend: false,
                                  photo: 'assets/test/umd.png',
                                  info: "$_schoolNickname",
                                  subInfo: "$_schoolFullname",
                                ),
                                SizedBox(width: 20),
                                InfoWidget(
                                  onTap: () {},
                                  isSchool: false,
                                  isFrirend: true,
                                  photo: 'assets/memoji/Memoji1.png',
                                  info: "Friends",
                                  subInfo: "${friendsCount} friends",
                                ),
                                SizedBox(width: 20),
                                InfoWidget(
                                  onTap: () =>
                                      setState(() => isJustGPA = !isJustGPA),
                                  isSchool: true,
                                  isFrirend: false,
                                  photo: 'assets/memoji/Memoji1.png',
                                  info: isJustGPA ? "GPA" : "Total GPA",
                                  subInfo: isJustGPA ? "0.00" : "3.33",
                                  isIcon: true,
                                ),
                                SizedBox(width: 20),
                                InfoWidget(
                                  onTap: () => setState(
                                      () => isJustCredit = !isJustCredit),
                                  isSchool: true,
                                  isFrirend: false,
                                  photo: 'assets/memoji/Memoji1.png',
                                  info:
                                      isJustCredit ? "Credit" : "Total Credit",
                                  subInfo: isJustCredit
                                      ? "0 credits"
                                      : "135 credits",
                                  isIcon: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Text(
                                "GPA",
                                style: TextStyle(
                                  fontSize: 25,
                                  color: Theme.of(context).colorScheme.outline,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Spacer(),
                              GestureDetector(
                                onTap: () {
                                  checkAccessToken();
                                  HapticFeedback.lightImpact();
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      fullscreenDialog: true,
                                      builder: (context) =>
                                          GPAPage(semester: _semester),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Container(
                                    height: 30,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text('More',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outline,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 10, right: 10, bottom: 10),
                          child: GPAGraph(
                            chartData: totalSemester
                                .map((data) =>
                                    GraphData(data.semester, data.grade))
                                .toList(),
                          ),
                        ),
                        SizedBox(height: 10),
                        //  PremiumWidget(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            "Course Colors ",
                            style: TextStyle(
                              fontSize: 25,
                              color: Theme.of(context).colorScheme.outline,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        CustomizeCourseColor(onTap: () {
                          checkAccessToken();
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              fullscreenDialog: true,
                              builder: (context) => ChangeCourseColorPage(),
                            ),
                          );
                        }),

                        SizedBox(height: 10),
                        //  PremiumWidget(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            "Feedback",
                            style: TextStyle(
                              fontSize: 25,
                              color: Theme.of(context).colorScheme.outline,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: GestureDetector(
                                onTap: _launchURL,
                                child: Container(
                                  width: MediaQuery.sizeOf(context).width,
                                  height: 70.0,
                                  decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Please send us Feedback',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Icon(
                                          Icons.keyboard_arrow_right,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
                                          size: 20,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            SignoutButton(
                              'Sign out',
                              Color.fromARGB(255, 243, 154, 168),
                              () async {
                                HapticFeedback.lightImpact();
                                await logoutUser();
                                Navigator.pushReplacement(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) => InitialPage(),
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
