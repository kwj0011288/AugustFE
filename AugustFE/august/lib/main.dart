import 'package:august/components/provider/course_color_provider.dart';
import 'package:august/components/provider/friends_provider.dart';
import 'package:august/const/dark_theme.dart';
import 'package:august/const/light_theme.dart';
import 'package:august/get_api/onboard/get_department.dart';
import 'package:august/login/initialpage.dart';
import 'package:august/login/login.dart';
import 'package:august/onboard/profile.dart';
import 'package:august/onboard/semester.dart';
import 'package:august/pages/profile/me_page.dart';
import 'package:august/pages/main/no_network_page.dart';
import 'package:august/pages/main/schedule_page.dart';
import 'package:august/pages/main/wizard_page.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'components/provider/courseprovider.dart';
import 'components/timetable/timetable.dart';
import 'get_api/timetable/class_grouping.dart';
import 'get_api/onboard/get_semester.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isOnline = await InternetConnectionChecker().hasConnection;
  List<String> preloadedSemesters;
  String _semester = prefs.getString('semester') ?? 'Error';
  List<String> departments;
  String? email;

  if (isOnline) {
    await checkAccessToken();
    // 앱 시작 시 항상 refreshToken을 사용하여 accessToken 갱신 시도
    await refreshToken();
    preloadedSemesters = await fetchAllSemesters();
    departments = await fetchDepartments();
    email = await fetchUserEmail();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('loadDone', false);
    await prefs.setString('semester', preloadedSemesters.last);
    await prefs.remove('contactPhoto');
    await prefs.remove('codeExpires');
    await prefs.remove('invitationCode');
    //await prefs.clear();
  } else {
    preloadedSemesters = ["Error"];
    departments = ["Error"];
    email = "Error";
  }

  runApp(MyApp(
    preloadedSemesters: preloadedSemesters,
    initialSemester:
        preloadedSemesters.isNotEmpty ? preloadedSemesters.last : "202208",
    semester: _semester,
    departments: departments,
    isOnline: isOnline,
  ));
}

class MyApp extends StatelessWidget {
  final List<String> preloadedSemesters;
  final String initialSemester;
  final String semester;
  final List<String> departments;
  final bool isOnline;

  MyApp({
    required this.preloadedSemesters,
    required this.initialSemester,
    required this.semester,
    required this.departments,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    print(preloadedSemesters);
    Widget initialScreen = isOnline
        ? InitialPage(
            departments: departments,
            preloadedSemesters: preloadedSemesters,
          )
        : NoNetworkPage();
    return Sizer(
      builder: (context, Orientation, DeviceType) {
        var courses = CoursesProvider();

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (context) => SemesterProvider(initialSemester),
            ),
            ChangeNotifierProvider(create: (context) => courses),
            ChangeNotifierProvider(create: (context) => ClassGrouping()),
            ChangeNotifierProvider(create: (context) => StartTimeProvider()),
            ChangeNotifierProvider(
                create: (context) => TimetablesProvider(courses)),
            ChangeNotifierProvider(
              create: (context) => SemestersProvider(preloadedSemesters),
            ),
            ChangeNotifierProvider(
              create: (context) => SavedSemesterProvider(semester),
            ),

            /* --- 아래는 정상 ---- */
            ChangeNotifierProvider(create: (_) => CurrentIndexProvider()),
            ChangeNotifierProvider(create: (_) => ProfilePhotoNotifier()),
            ChangeNotifierProvider(create: (_) => FriendsProvider()),
            ChangeNotifierProvider(create: (context) => CourseColorProvider()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: dartTheme,
            home: initialScreen,
          ),
        );
      },
    );
  }
}
