import 'package:august/components/provider/course_color_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomizeCourseColor extends StatefulWidget {
  final VoidCallback onTap;

  CustomizeCourseColor({required this.onTap});

  @override
  _CustomizeCourseColorState createState() => _CustomizeCourseColorState();
}

class _CustomizeCourseColorState extends State<CustomizeCourseColor> {
  @override
  Widget build(BuildContext context) {
    var courseColorProvider = Provider.of<CourseColorProvider>(context);
    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: 70.0, // Set the desired size
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: courseColorProvider.colors,
              stops: courseColorProvider.stops,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow,
                blurRadius: 10, // 블러 효과를 줄여서 그림자를 더 세밀하게
                offset: Offset(4, -1), // 좌우 그림자의 길이를 줄임
              ),
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow,
                blurRadius: 10,
                offset: Offset(-1, 0), // 좌우 그림자의 길이를 줄임
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Customize Course Colors',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_right,
                  color: Colors.black,
                  size: 20,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
