import 'dart:io';

import 'package:august/components/button.dart';
import 'package:august/login/login.dart';
import 'package:august/login/loginpage.dart';
import 'package:august/pages/homepage.dart';
import 'package:august/pages/schedule_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:auth_buttons/auth_buttons.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gaimon/gaimon.dart';

class InitialPage extends StatefulWidget {
  final List<String> departments;
  final List<String> preloadedSemesters;
  final bool guest;

  const InitialPage({
    super.key,
    required this.departments,
    required this.preloadedSemesters,
    this.guest = false,
  });

  @override
  State<InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '182477252206-0oadnqer56to4c3d11n62of8g8ca3frh.apps.googleusercontent.com',
    scopes: <String>[
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );
// 사진 보낼때 file로 보내야됌
  Future<void> _loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      final String? accessToken = googleAuth?.accessToken;
      final String? idToken = googleAuth?.idToken;

      if (googleUser == null || accessToken == null || idToken == null) {
        print(
            'Google login was cancelled by the user or failed to receive ID token.');
        return;
      }

      String requestBody =
          jsonEncode({'access_token': accessToken, 'id_token': idToken});
      final response = await http.post(
        Uri.parse('http://augustapp.one/users/google/login/callback/'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final newAccessToken = responseData['access'];
        final newRefreshToken = responseData['refresh'];
        final userPk = responseData['user']['id']; // Extract user PK

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', newAccessToken);
        await prefs.setString('refreshToken', newRefreshToken);
        await prefs.setInt('userPk', userPk);

        startTokenRefreshTimer(); // Start token refresh timer after successful login

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => HomePage(
                    departments: widget.departments,
                    preloadedSemesters: widget.preloadedSemesters,
                  )),
        );
      } else {
        print('Server error: ${response.body}');
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Login Failed"),
              content: Text("Server error occurred. Please try again."),
              actions: <Widget>[
                TextButton(
                  child: Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (error) {
      print('Error logging in with Google: $error');
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkLoginStatusAndNavigate();
  }

  Future<void> _checkLoginStatusAndNavigate() async {
    Future.microtask(() => showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  Text("Loading"),
                ],
              ),
            );
          },
        ));

    final isLoggedIn = await checkLoginStatus(); // 기존에 구현된 로그인 상태 확인
    if (!isLoggedIn) {
      final isTokenRefreshed =
          await refreshToken(); // refresh token으로 새로운 access token 요청

      Navigator.pop(context); // 로딩 인디케이터 닫기
      if (isTokenRefreshed) {
        _navigateToHomePage(); // Homepage로 이동
      } else {
        // 토큰 갱신 실패 처리, 로그인 페이지로 유도 등
      }
    } else {
      Navigator.pop(context); // 로딩 인디케이터 닫기
      await fetchAndPrintUserInfo(); // 사용자 정보 출력
      _navigateToHomePage(); // Homepage로 이동
    }
  }

  void _navigateToHomePage() {
    if (!mounted)
      return; // Add this line to check if the widget is still mounted

    HapticFeedback.heavyImpact();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => HomePage(
          departments: widget.departments,
          preloadedSemesters: widget.preloadedSemesters,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(animation);

          return FadeTransition(
            opacity: fadeAnimation,
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 650), // 애니메이션 속도 조정
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: ColorfulSafeArea(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: RichText(
                  text: TextSpan(
                    text: 'Welcome to ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'August',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 25),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppleAuthButton(
                    themeMode: ThemeMode.dark,
                    onPressed: () {},
                    style: AuthButtonStyle(
                      buttonColor: Colors.black,
                      borderRadius: 18,
                      iconSize: 24,
                      separator: 10,
                      textStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      width: MediaQuery.of(context).size.width, // 버튼의 너비 설정
                      height: 60.0, // 버튼의 높이 설정
                    ),
                  ),
                  SizedBox(height: 15), // 세로 간격 조정
                  GoogleAuthButton(
                    onPressed: _loginWithGoogle,
                    style: AuthButtonStyle(
                      buttonColor: Colors.white,
                      iconSize: 24,
                      borderRadius: 18,
                      separator: 10,
                      borderColor: Colors.black,
                      borderWidth: 1,
                      textStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                      width: MediaQuery.of(context).size.width, // 버튼의 너비 설정
                      height: 60.0, // 버튼의 높이 설정
                    ),
                  ),
                  SizedBox(height: 10), // 세로 간격 조정
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10, top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: Text(
                            'This is a TEST version...\nRequest Permission to AugustAppHelp2@gmail.com',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // TextButton(
                        //   onPressed: () {
                        //     HapticFeedback.mediumImpact();
                        //     Navigator.push(
                        //       context,
                        //       CupertinoPageRoute(
                        //         builder: (context) => LoginPage(),
                        //       ),
                        //     );
                        //   },
                        //   child: Text(
                        //     'Sign in with Email',
                        //     style: TextStyle(
                        //         color: Theme.of(context).colorScheme.outline,
                        //         fontSize: 18,
                        //         fontWeight: FontWeight.bold),
                        //   ),
                        // ),
                        // TextButton(
                        //   onPressed: () async {
                        //     // 팝업 띄우기
                        //     final result = await showDialog(
                        //       context: context,
                        //       builder: (context) => AlertDialog(
                        //         title: Text('Beta Test'),
                        //         content: Text(
                        //             'Sometimes Google login might not work. Using this mode will be the best choice.'),
                        //         actions: <Widget>[
                        //           TextButton(
                        //             onPressed: () =>
                        //                 Navigator.of(context).pop(false),
                        //             child: Text(
                        //               'Cancel',
                        //               style: TextStyle(
                        //                 color: Theme.of(context)
                        //                     .colorScheme
                        //                     .outline,
                        //               ),
                        //             ),
                        //           ),
                        //           TextButton(
                        //             onPressed: () =>
                        //                 Navigator.of(context).pop(true),
                        //             child: Text(
                        //               'Continue',
                        //               style: TextStyle(
                        //                 color: Theme.of(context)
                        //                     .colorScheme
                        //                     .outline,
                        //               ),
                        //             ),
                        //           ),
                        //         ],
                        //       ),
                        //     );

                        //     // 팝업에서 'Continue'를 누른 경우 HomePage로 이동
                        //     if (result == true) {
                        //       HapticFeedback.mediumImpact();
                        //       Navigator.push(
                        //         context,
                        //         CupertinoPageRoute(
                        //           builder: (context) => HomePage(
                        //             departments: widget.departments,
                        //             preloadedSemesters:
                        //                 widget.preloadedSemesters,
                        //             guest: true,
                        //           ),
                        //         ),
                        //       );
                        //     }
                        //   },
                        //   child: Text(
                        //     'For Beta Testers',
                        //     style: TextStyle(
                        //       color: Theme.of(context).colorScheme.outline,
                        //       fontSize: 18,
                        //       fontWeight: FontWeight.bold,
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
