import 'package:flutter/material.dart';

class StackedPhoto extends StatelessWidget {
  final List<String> imagePaths;

  const StackedPhoto({Key? key, required this.imagePaths}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> stackedImages = [];
    for (int i = 0; i < imagePaths.length; i++) {
      stackedImages.add(
        Positioned(
          right: i * 15.0, // Incremental offset for each image
          child:
              Image.asset(imagePaths[i], width: 50), // Adjust width as needed
        ),
      );
    }

    return Container(
      width: imagePaths.length * 27.0, // Ensure container is wide enough
      height: 50,
      child: Stack(
        children: stackedImages,
      ),
    );
  }
}
