import 'package:august/provider/course_color_provider.dart';
import 'package:august/provider/friends_provider.dart';
import 'package:august/const/theme/dark_theme.dart';
import 'package:august/const/theme/light_theme.dart';
import 'package:august/get_api/onboard/get_department.dart';
import 'package:august/login/initialpage.dart';
import 'package:august/login/login.dart';
import 'package:august/onboard/profile.dart';
import 'package:august/pages/main/no_network_page.dart';
import 'package:august/pages/main/schedule_page.dart';
import 'package:august/provider/Institution_provider.dart';
import 'package:august/provider/department_provider.dart';
import 'package:august/provider/semester_provider.dart';
import 'package:august/provider/user_info_provider.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'provider/courseprovider.dart';
import 'get_api/timetable/class_grouping.dart';
import 'get_api/onboard/get_semester.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Add this line
  MobileAds.instance.initialize();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isOnline = await InternetConnectionChecker().hasConnection;
  List<String> preloadedSemesters;
  List<String> departments;
  String? email;
  prefs.remove('semester');
  //prefs.clear();

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
    departments: departments,
    isOnline: isOnline,
  ));
}

class MyApp extends StatelessWidget {
  final List<String> preloadedSemesters;
  final String initialSemester;
  final List<String> departments;
  final bool isOnline;

  MyApp({
    required this.preloadedSemesters,
    required this.initialSemester,
    required this.departments,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    print(preloadedSemesters);
    Widget initialScreen = isOnline ? InitialPage() : NoNetworkPage();
    return Sizer(
      builder: (context, Orientation, DeviceType) {
        return MultiProvider(
          providers: [
            // ChangeNotifierProvider(
            //   create: (context) => TestSemesterProvider(initialSemester),
            // ),
            ChangeNotifierProvider(create: (context) => CoursesProvider()),
            ChangeNotifierProvider(create: (context) => ClassGrouping()),

            // ChangeNotifierProvider(
            //   create: (context) => SemestersProvider(preloadedSemesters),
            // ),
            // ChangeNotifierProvider(
            //   create: (context) => SavedSemesterProvider(semester),
            // ),

            /* --- 아래는 정상 ---- */
            ChangeNotifierProvider(create: (_) => CurrentIndexProvider()),
            ChangeNotifierProvider(create: (_) => ProfilePhotoNotifier()),
            ChangeNotifierProvider(create: (_) => FriendsProvider()),
            /* --- course & personasl info provider ====  */
            ChangeNotifierProvider(create: (_) => SemesterProvider()),
            ChangeNotifierProvider(create: (context) => CourseColorProvider()),
            ChangeNotifierProvider(create: (context) => DepartmentProvider()),
            ChangeNotifierProvider(create: (context) => InstitutionProvider()),
            ChangeNotifierProvider(create: (context) => UserInfoProvider()),
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
