import 'package:august/pages/homepage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(_createRoute());
    });
  }

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => HomePage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = 0.0;
        var end = 1.0;
        var curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var fadedAnimation = animation.drive(tween);

        return FadeTransition(
          opacity: fadedAnimation,
          child: child,
        );
      },
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'I do not have an icon yet....',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.black,
                fontSize: 32,
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              'August',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.black,
                fontSize: 32,
              ),
            )
          ],
        ),
      ),
    );
  }
}
