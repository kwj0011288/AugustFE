import 'package:august/components/home/my_bottombar.dart';
import 'package:august/const/save_image.dart';
import 'package:august/get_api/friends/get_friends.dart';
import 'package:august/get_api/onboard/get_semester.dart';
import 'package:august/login/login.dart';
import 'package:august/onboard/onboard.dart';
import 'package:august/onboard/semester.dart';
import 'package:august/pages/gpa/gpa_page.dart';
import 'package:august/pages/profile/me_page.dart';
import 'package:august/pages/search/search_page.dart';
import 'package:provider/provider.dart';
import 'package:august/pages/friends/friends_page.dart';
import 'package:august/pages/main/schedule_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  final List<String> departments;
  final List<String> preloadedSemesters;
  final bool guest;

  const HomePage({
    Key? key,
    this.departments = const [],
    this.preloadedSemesters = const [],
    this.guest = false,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 1;
  String? _semester;
  bool isLoading = true;
  List<Widget> _pages = [];
  Map<String, dynamic>? userInfo;
  bool isFirst = true;
  bool _showBottomBar = false;

  Future<void> loadSemesterInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedSemester = prefs.getString('semester');
    String formattedSemester;
    if (storedSemester != null) {
      try {
        formattedSemester = getOriginalSemester(storedSemester);
      } catch (e) {
        formattedSemester = '202008';
      }
    } else {
      formattedSemester = widget.preloadedSemesters.last;
    }

    setState(() {
      _semester = formattedSemester;
    });
  }

  void checkAndShowOnBoarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? onBoard = prefs.getBool('hasSeenOnboard') ?? false;
    if (isFirst || !onBoard) {
      await Navigator.of(context).push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => OnBoardPage(
          preloadedSemesters: widget.preloadedSemesters,
          onBoardingComplete: () async {
            Navigator.of(context).pop(); // Dismiss the OnBoardPage
            // Optionally refresh the HomePage or perform other actions
          },
          departments: widget.departments,
        ),
      ));
      // Set hasSeenOnboard to true after the OnBoardPage is dismissed
      prefs.setBool('hasSeenOnboard', true);
      await prefs.setBool('isFirst', false);
      print('isFirst updated to: $isFirst');
      //logger.log('isFirst updated to: $isFirst');
    }
  }

  @override
  void initState() {
    super.initState();
    initializeApp();
    _showBottomBar = true;
  }

  Future<void> initializeApp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // isFirst 값이 로컬ㄹ에 저장되었는지 확인
    bool? hasCheckedFirst = prefs.getBool('hasCheckedFirst');
    if (hasCheckedFirst == null) {
      await fetchAndSetUserInfo(true);
      // 앱이 처음 실행되는 경우, isFirst 값을 계산하여 저장
      String dateJoined = userInfo?['dateJoined'] ?? '2021-01-01T00:00:00.000Z';
      print(dateJoined);
      print('dateJoined: $dateJoined');
      isFirst = isTodayOrWithin5min(dateJoined);
      await prefs.setBool('hasCheckedFirst', true);
      await prefs.setBool('isFirst', isFirst);
    } else {
      // 이미 저장된 isFirst 값을 사용
      isFirst = prefs.getBool('isFirst') ?? false;
      updateAndPrintIsFirst(isFirst); // or false
    }

    if (!isFirst && widget.preloadedSemesters.isNotEmpty) {
      // Access the SavedSemesterProvider and set the selected semester
      SavedSemesterProvider provider =
          Provider.of<SavedSemesterProvider>(context, listen: false);
      provider
          .setSelectedSemester(formatSemester(widget.preloadedSemesters.last));
      fetchAndSetUserInfo(isFirst);
    }

    await Future.wait([
      // loadSemesterInfo와 fetchAndSetUserInfo 함수들이 백그라운드에서 동시에 실행될 수 있도록 변경
      loadSemesterInfo(),
      if (isFirst) fetchAndSetUserInfo(isFirst),
    ]);

    if (isFirst == true) {
      // isFirst가 true인 경우에만 onBoarding 체크
      Future.delayed(Duration(milliseconds: 500), () async {
        checkAndShowOnBoarding();
      });
    } else {
      _initializePages();
    }

    setState(() {
      isLoading = false;
    });
  }

  String formatSemester(String semester) {
    String year = semester.substring(0, 4);
    String season = getSeasonFromSemester(semester);
    return "$season $year";
  }

  bool isTodayOrWithin5min(String dateJoinedStr) {
    DateTime dateJoined = DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'")
        .parseUtc(dateJoinedStr)
        .toLocal();
    DateTime now = DateTime.now();
    print(now);

    // 현재 시간과 dateJoined의 날짜, 시간, 분을 비교하여 10분 이내 차이나는지 확인
    Duration difference = now.difference(dateJoined);
    bool isTodayAndWithin5Minutes = now.year == dateJoined.year &&
        now.month == dateJoined.month &&
        now.day == dateJoined.day &&
        difference.inMinutes.abs() <= 5;

    return isTodayAndWithin5Minutes;
  }

  void _initializePages() {
    // 페이지 초기화 로직을 별도 함수로 분리하여, 필요한 경우에만 호출
    _pages = [
      SearchPage(semester: _semester!),
      SchedulePage(
        semester: _semester ?? '202401',
        departments: widget.departments,
        guest: widget.guest,
        firstTime: isFirst,
        preloadedSemesters: widget.preloadedSemesters,
      ),
      FriendsPage(
        semester: _semester ?? 'Unknown',
      ),
      Mypage(
        selectedSemester: _semester!,
        isFirst: isFirst,
        departments: widget.departments,
      )
    ];
  }

  Future<void> fetchAndSetUserInfo(bool isFirstTime) async {
    final userDetails =
        await fetchUserDetails(); // fetchUserDetails 함수를 비동기적으로 호출
    String displayGrade = 'Unknown'; // 기본값 설정
    if (userDetails != null && !isFirstTime) {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // 서버로부터 받은 yearInSchool 값에 대한 변환 로직
      String displayGrade = convertGrade(userDetails.yearInSchool); // 변환 함수 사용

      ProfileImageHandler imageHandler = ProfileImageHandler();
      if (userDetails.profileImage != null) {
        await imageHandler.downloadAndSaveImageAsBase64(
            userDetails.profileImage, 'contactPhoto');
      }

      // SharedPreferences에 저장하기 전에 변환된 값을 사용
      await prefs.setString('name', userDetails.name);
      await prefs.setString('grade', displayGrade); // 수정된 부분: 변환된 학년 정보 사용
      await prefs.setString(
          'major', userDetails.department?.nickname ?? 'Unknown');

      await prefs.setString(
          'fullname', userDetails.institution?.fullName ?? 'Unknown');
      await prefs.setString(
          'nickname', userDetails.institution?.nickname ?? 'Unknown');

      await prefs.setString('userEmail', userDetails.email);

      if (widget.preloadedSemesters.isNotEmpty) {
        await prefs.setString(
            'semester', formatSemester(widget.preloadedSemesters.last));
      } else {
        await prefs.setString('semester',
            '202404'); // Adjust the default semester code as needed.
      }
    }

    if (userDetails != null && mounted) {
      // 여기서 mounted 검사를 하여 dispose된 후에는 setState를 호출하지 않음
      setState(() {
        userInfo = {
          'id': userDetails.id,
          'email': userDetails.email,
          'name': userDetails.name,
          'institution_fullname':
              userDetails.institution?.fullName ?? 'Unknown',
          'institution_nickname':
              userDetails.institution?.nickname ?? 'Unknown',
          'department_fullname': userDetails.department?.fullName ?? 'Unknown',
          'department_nickname': userDetails.department?.nickname ?? 'Unknown',
          'contactPhoto': userDetails.profileImage,
          'yearInSchool': displayGrade,
          'dateJoined': userDetails.dateJoined,
        };
      });
    }
  }

  void updateAndPrintIsFirst(bool newValue) {
    setState(() {
      isFirst = newValue;
      print('isFirst updated to: $isFirst');
    });
  }

  String convertGrade(String code) {
    switch (code) {
      case 'FR':
        return 'Freshman';
      case 'SO':
        return 'Sophomore';
      case 'JR':
        return 'Junior';
      case 'SR':
        return 'Senior';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
              Theme.of(context).colorScheme.primaryContainer.withOpacity(1.0),
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
        ),
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: AnimatedOpacity(
          opacity: _showBottomBar ? 1.0 : 0.0,
          duration: Duration(seconds: 1),
          child: BottomBar(
            onIndexChanged: (index) {
              checkAccessToken();
              if (_currentIndex != index) {
                setState(() {
                  _currentIndex = index;
                });
              }
            },
            semester: _semester ?? '202401',
            isFirst: isFirst,
          ),
        ),
      ),
    );
  }
}
