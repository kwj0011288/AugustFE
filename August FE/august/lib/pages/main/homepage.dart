import 'package:august/components/home/my_bottombar.dart';
import 'package:august/components/profile/profile.dart';
import 'package:august/const/device/device_util.dart';
import 'package:august/const/customs/save_image.dart';
import 'package:august/login/login.dart';
import 'package:august/onboard/onboard.dart';
import "package:flutter_feather_icons/flutter_feather_icons.dart";
import 'package:august/pages/profile/me_page.dart';
import 'package:august/pages/search/search_page.dart';
import 'package:august/provider/semester_provider.dart';
import 'package:provider/provider.dart';
import 'package:august/pages/friends/friends_page.dart';
import 'package:august/pages/main/schedule_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    Key? key,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 1;
  String? currentSemester;
  bool isLoading = true;
  List<Widget> _pages = [];
  Map<String, dynamic>? userInfo;
  bool isFirst = true;
  bool _showBottomBar = false;

  void checkAndShowOnBoarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? onBoard = prefs.getBool('hasSeenOnboard') ?? false;
    if (isFirst || !onBoard) {
      await Navigator.of(context).push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => OnBoardPage(),
      ));

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    currentSemester = Provider.of<SemesterProvider>(context).semester;
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

    if (!isFirst) {
      fetchAndSetUserInfo(isFirst);
    }
    /*
       if (!isFirst && widget.preloadedSemesters.isNotEmpty) {
      Provider.of<SemesterProvider>(context, listen: false)
          .setSelectedSemester(formatSemester(widget.preloadedSemesters.last));
      fetchAndSetUserInfo(isFirst);
    }
     */

    await Future.wait([
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
    _pages = [SearchPage(), SchedulePage(), FriendsPage(), Mypage()];
  }

  Future<void> fetchAndSetUserInfo(bool isFirstTime) async {
    final semester =
        Provider.of<SemesterProvider>(context, listen: false).semester;
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
      await prefs.setString('logo', userDetails.institution?.logo ?? 'Unknown');

      await prefs.setString('userEmail', userDetails.email);

      await prefs.setString('semester', semester);
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
          'logo': userDetails.institution?.logo ?? 'Unknown',
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
      body: Column(
        children: <Widget>[
          DeviceUtils.isTablet(context) ? tabBar() : Container(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children:
                  _pages, // Assuming _pages contains the content for each tab
            ),
          ),
        ],
      ),
      bottomNavigationBar: DeviceUtils.isTablet(context) ? null : bottomBar(),
    );
  }

  Widget bottomBar() {
    return Padding(
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
        ),
      ),
    );
  }

  Widget tabBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: CustomSlidingSegmentedControl(
        innerPadding: EdgeInsets.all(5),
        curve: Curves.easeInOutCirc,
        children: {
          1: Container(
            width: 50,
            child: Icon(
              FeatherIcons.layout,
            ),
          ),
          2: Container(
            width: 50,
            child: Icon(
              Icons.people,
            ),
          ),
          3: Container(
            width: 50,
            child: ProfileWidget(
              isBottomBar: true,
            ),
          )
        },
        onValueChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(100),
        ),
        thumbDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background.withOpacity(0.5),
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
  }
}
