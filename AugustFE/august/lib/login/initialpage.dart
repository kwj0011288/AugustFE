import 'dart:io';

import 'package:august/login/login.dart';
import 'package:august/pages/main/homepage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:auth_buttons/auth_buttons.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'dart:math';

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
        '469588470984-or2haks4c471937fblbnc1j26061n6d1.apps.googleusercontent.com',
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
        Uri.parse('https://augustapp.one/users/google/login/callback/'),
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
        showLoginPrompt(context);
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
    // Show loading indicator
    Future.microtask(
      () => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Center(
              child: Container(
                width: 100, // Adjust as needed
                height: 100, // Adjust as needed
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(100), // Adjust as needed
                ),
                child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.outline,
                    )),
              ),
            ),
          );
        },
      ),
    );

    final isLoggedIn = await checkLoginStatus(); // Check current login status

    if (!isLoggedIn) {
      final isTokenRefreshed =
          await refreshToken(); // Attempt to refresh the token

      if (isTokenRefreshed) {
        // If token refresh is successful, fetch user info and navigate to homepage
        if (await fetchAndPrintUserInfo(context)) {
          Navigator.pop(context); // Close loading indicator
          _navigateToHomePage(); // Navigate to homepage
        } else {
          // If fetching user info fails, show login prompt
          Navigator.pop(context); // Close loading indicator
          print('1');
          showLoginPrompt(context);
        }
      } else {
        // If token refresh fails, logout the user and show login prompt
        logoutUser();
        print('2');
        Navigator.pop(context); // Close loading indicator
      }
    } else {
      // If already logged in, fetch user info and navigate to homepage
      if (await fetchAndPrintUserInfo(context)) {
        Navigator.pop(context); // Close loading indicator
        print('3');
        _navigateToHomePage(); // Navigate to homepage
      } else {
        // If fetching user info fails, show login prompt
        Navigator.pop(context); // Close loading indicator
        print('4');
        //showLoginPrompt(context);
      }
    }
  }

  void showLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            textAlign: TextAlign.center,
            'Login Failed',
            style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          actions: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 30),
                height: 55,
                width: MediaQuery.of(context).size.width - 80,
                decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(60)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'OK',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
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
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Share ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 35,
                          color: Theme.of(context).colorScheme.outline,
                          fontFamily: 'Apple',
                          height: 1.5,
                          letterSpacing: 1.2,
                        ),
                      ),
                      WidgetSpan(
                        child: Lottie.asset(
                          'assets/lottie/share.json',
                          height: 35,
                          width: 40,
                        ),
                      ),
                      TextSpan(
                        text: ' School life \n',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 35,
                          color: Theme.of(context).colorScheme.outline,
                          fontFamily: 'Apple',
                          letterSpacing: 1.2,
                        ),
                      ),
                      TextSpan(
                        text: 'With ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 35,
                          color: Colors.grey,
                          fontFamily: 'Apple',
                          letterSpacing: 1.2,
                        ),
                      ),
                      TextSpan(
                        text: ' Autocreated ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 35,
                          color: Theme.of(context).colorScheme.outline,
                          fontFamily: 'Apple',
                          height: 1.5,
                          letterSpacing: 1.2,
                        ),
                      ),
                      WidgetSpan(
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(pi),
                          child: Lottie.asset(
                            'assets/lottie/magic_wand.json',
                            height: 35,
                            width: 40,
                          ),
                        ),
                      ),
                      TextSpan(
                        text: 'Schedules!',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontWeight: FontWeight.bold,
                          fontSize: 35,
                          fontFamily: 'Apple',
                          height: 1.5,
                          letterSpacing: 1.2,
                        ),
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
                    onPressed: () {
                      print('apple login clicked');
                    },
                    style: AuthButtonStyle(
                      buttonColor: Theme.of(context).colorScheme.outline,
                      borderRadius: 18,
                      iconSize: 28,
                      iconColor: Theme.of(context).colorScheme.background,
                      separator: 10,
                      splashColor: Theme.of(context)
                          .colorScheme
                          .background
                          .withOpacity(0.1),
                      textStyle: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.background,
                        fontWeight: FontWeight.normal,
                        fontFamily: 'Apple',
                      ),
                      width: MediaQuery.of(context).size.width,
                      height: 56.0,
                    ),
                  ),
                  SizedBox(height: 20),
                  GoogleAuthButton(
                    onPressed: _loginWithGoogle,
                    style: AuthButtonStyle(
                      buttonColor: Colors.white,
                      iconSize: 28,
                      borderRadius: 18,
                      separator: 10,
                      borderColor: Colors.black,
                      borderWidth: 1,
                      splashColor: Theme.of(context)
                          .colorScheme
                          .background
                          .withOpacity(0.1),
                      textStyle: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.normal,
                        fontFamily: 'Apple',
                      ),
                      width: MediaQuery.of(context).size.width,
                      height: 60,
                    ),
                  ),
                  SizedBox(height: 40),
                  Text.rich(
                    TextSpan(
                      text:
                          'By signing up for an account in August, you confirm that\nyou have read and agreed to our ',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        fontFamily: 'Apple',
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Terms of Use',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.grey,
                            color: Colors.grey,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              print('Terms of Use clicked');
                            },
                        ),
                        TextSpan(
                          text: ' and ',
                          style: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Apple',
                          ),
                        ),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.grey,
                            color: Colors.grey,
                            fontFamily: 'Apple',
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              print('Policy clicked');
                            },
                        ),
                        TextSpan(
                          text: '.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Apple',
                          ),
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
    );
  }
}
