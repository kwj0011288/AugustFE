import 'package:august/const/tile_color.dart';
import 'package:flutter/material.dart';

Widget animationFriend(Color color, String imagePath) {
  return Container(
    child: Builder(
      builder: (context) {
        return Transform.translate(
          offset: const Offset(0.0, 5.0),
          child: Container(
            padding: EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 130,
                  height: 150,
                  child: CircleAvatar(
                    backgroundImage: AssetImage(imagePath),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "August",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget AnimationFriends(BuildContext context) {
  // Define constants for easier adjustments
  const double distance = 50.0; // Constant distance for all side widgets
  const double farDistance = 90.0; // Distance for the farthest widgets
  const double scaleCenter = 1.0; // Scale for the center widget
  const double scaleSide = 0.9; // Scale for side widgets
  const double scaleFarSide = 0.8; // Scale for the farthest side widgets

  List<Widget> widgets = [];

  // Generate far left widget (visually further back)
  widgets.add(Transform.translate(
    offset: Offset(-1 * farDistance, 0),
    child: Transform.scale(
      scale: scaleFarSide,
      child: animationFriend(Theme.of(context).colorScheme.onSecondary,
          "assets/memoji/Memoji1.png"),
    ),
  ));

  // Generate left widget (visually further back)
  widgets.add(Transform.translate(
    offset: Offset(-1 * distance, 0),
    child: Transform.scale(
      scale: scaleSide,
      child: animationFriend(
          makeBrighter(Theme.of(context).colorScheme.onSecondary, 0.1),
          "assets/memoji/Memoji2.png"),
    ),
  ));
// Generate far right widget (visually further back)
  widgets.add(Transform.translate(
    offset: Offset(1 * farDistance, 0),
    child: Transform.scale(
      scale: scaleFarSide,
      child: animationFriend(Theme.of(context).colorScheme.onSecondary,
          "assets/memoji/Memoji3.png"),
    ),
  ));

  // Generate right widget (visually further back)
  widgets.add(Transform.translate(
    offset: Offset(1 * distance, 0),
    child: Transform.scale(
      scale: scaleSide,
      child: animationFriend(
          makeBrighter(Theme.of(context).colorScheme.onSecondary, 0.1),
          "assets/memoji/Memoji4.png"),
    ),
  ));

  // Generate center widget (visually at the front)
  widgets.add(Transform.translate(
    offset: Offset(0, 0),
    child: Transform.scale(
      scale: scaleCenter,
      child: animationFriend(Theme.of(context).colorScheme.onSecondary,
          "assets/memoji/Memoji1.png"),
    ),
  ));

  return Stack(
    alignment: Alignment.center,
    children: widgets,
  );
}
