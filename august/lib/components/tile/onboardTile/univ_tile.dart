import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bouncing_widgets/custom_bounce_widget.dart';

class UniversityTile extends StatefulWidget {
  final String fullname;
  final String nickname;
  final VoidCallback onTap;
  final Color tileColor;
  final bool isShadow;

  const UniversityTile({
    Key? key,
    required this.fullname,
    required this.nickname,
    required this.onTap,
    required this.tileColor,
    required this.isShadow,
  }) : super(key: key);

  @override
  _UniversityTileState createState() => _UniversityTileState();
}

class _UniversityTileState extends State<UniversityTile> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CustomBounceWidget(
        onPressed: widget.onTap,
        duration: Duration(milliseconds: 100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            height: 70,
            width: double.infinity,
            decoration: BoxDecoration(
              color: widget.tileColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                if (!widget.isShadow)
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow,
                    blurRadius: 10, // 블러 효과를 줄여서 그림자를 더 세밀하게
                    offset: Offset(4, -1), // 좌우 그림자의 길이를 줄임
                  ),
                if (!widget.isShadow)
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow,
                    blurRadius: 10,
                    offset: Offset(-1, 0), // 좌우 그림자의 길이를 줄임
                  ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  maxRadius: 30,
                  child: Image.asset(
                    'assets/test/umd.png', // 'assets/icons/university.svg
                    width: 30,
                    height: 30,
                  ),
                ),
                SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.nickname,
                      style: TextStyle(
                        fontSize: 20,
                        color: Theme.of(context).colorScheme.outline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.fullname,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
