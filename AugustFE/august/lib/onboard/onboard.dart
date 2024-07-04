import 'dart:typed_data';

import 'package:august/get_api/onboard/get_univ.dart';
import 'package:august/onboard/grade.dart';
import 'package:august/onboard/major.dart';
import 'package:august/onboard/profile.dart';
import 'package:august/onboard/semester.dart';
import 'package:august/onboard/univ.dart';
import 'package:august/pages/main/homepage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnBoardPage extends StatefulWidget {
  final List<String> preloadedSemesters;
  final Function() onBoardingComplete;
  final List<String> departments;
  const OnBoardPage(
      {super.key,
      required this.preloadedSemesters,
      required this.onBoardingComplete,
      required this.departments});

  @override
  _OnBoardPageState createState() => _OnBoardPageState();
}

class _OnBoardPageState extends State<OnBoardPage> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  List<Institution> schoolsList = [];

  @override
  void initState() {
    super.initState();
    fetchInstitutions().then((loadedInstitutions) {
      setState(() {
        schoolsList = loadedInstitutions;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _completeOnBoarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboard', true);
    widget.onBoardingComplete();
  }

  void _navigateToPrevious() {
    if (_currentPage > 0) {
      // 현재 페이지가 첫 페이지가 아니라면, 이전 페이지로 이동
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToNextOrHome() async {
    if (_currentPage < _pages.length - 1) {
      // Not the last page, navigate to the next page
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      // Last page, set the flag and navigate to the homepage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenOnboard', true);

      Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => HomePage(
              departments: widget.departments,
              preloadedSemesters: widget.preloadedSemesters,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              // Use a FadeTransition instead of a SlideTransition
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ));
    }
  }

  List<Widget> get _pages => [
        NamePage(
          onboard: true,
          onTap: _navigateToNextOrHome,
          onPhotoUpdated: (Uint8List? updatedPhoto) {},
        ),
        UnivPage(
          onboard: true,
          gonext: _navigateToNextOrHome,
          goBack: _navigateToPrevious,
          institutions: schoolsList,
        ),
        SemesterPage(
          preloadedSemesters: widget.preloadedSemesters,
          onboard: true,
          gonext: _navigateToNextOrHome,
          goBack: _navigateToPrevious,
        ),
        GradePage(
          onboard: true,
          gonext: _navigateToNextOrHome,
          goBack: _navigateToPrevious,
        ),
        MajorPage(
          onboard: true,
          gonext: _navigateToNextOrHome,
          goBack: _navigateToPrevious,
          preloadedDepartments: widget.departments,
        )
      ];

  @override
  Widget build(BuildContext context) {
    print(widget.preloadedSemesters);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageView(
        controller: _pageController,
        onPageChanged: (int page) {
          setState(() {
            _currentPage = page;
          });
        },
        physics: const NeverScrollableScrollPhysics(), // 스와이프로 페이지 넘김 방지
        children: _pages,
      ),
    );
  }
}
