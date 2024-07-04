import 'package:august/components/home/button.dart';
import 'package:august/components/provider/course_color_provider.dart';
import 'package:august/const/colors/modify_color.dart';
import 'package:august/const/dark_theme.dart';
import 'package:august/const/light_theme.dart';
import 'package:flutter/material.dart';
import '../../get_api/timetable/class.dart';
import 'package:provider/provider.dart';

class SimepleCourseTile extends StatefulWidget {
  final CourseList classes;
  final String sectionCode;
  final String instructorName;
  final String meetingTimes;
  final int fullSeat;
  final int openSeat;
  final int waitlist;
  final int holdfile;
  final void Function(BuildContext context)? onPressed;
  final void Function(BuildContext context)? onTap;
  final IconData icon;
  final IconData? toggledIcon;
  final Function? onIconToggled;
  final Color backgroundColor;
  final int index;

  // 네임드 파라미터를 사용하고 onPressed와 onTap을 nullable로 변경
  const SimepleCourseTile({
    Key? key,
    required this.classes,
    this.onPressed,
    this.onTap,
    required this.icon,
    this.toggledIcon,
    this.onIconToggled,
    required this.backgroundColor,
    required this.index,
    required this.sectionCode,
    required this.instructorName,
    required this.meetingTimes,
    required this.fullSeat,
    required this.openSeat,
    required this.waitlist,
    required this.holdfile,
  }) : super(key: key);

  @override
  _ClassTileState createState() => _ClassTileState();
}

class _ClassTileState extends State<SimepleCourseTile> {
  bool check = false;

  Widget seatButton(String text, Color buttonColor, final VoidCallback onTap) {
    TextStyle buttonTextStyle = TextStyle(
      // Define your text style here
      fontSize: 9.5,
      fontWeight: FontWeight.bold,
    );

    double textWidth = calculateTextWidth(text, buttonTextStyle, context);
    double buttonWidth = textWidth; // Add some padding to the text width

    return Container(
      width: buttonWidth,
      height: 16,
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    List<Color> tileColors = theme.brightness == Brightness.dark
        ? darkenColors(
            lightenColors(
                Provider.of<CourseColorProvider>(context).colors, 0.102),
            0.05)
        : lightenColors(Provider.of<CourseColorProvider>(context).colors, 0.05);
    return Container(
      decoration: BoxDecoration(
        color: tileColors[widget.index % tileColors.length],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow,
            blurRadius: 10,
            offset: Offset(
              4,
              8,
            ),
          )
        ],
      ),
      margin: const EdgeInsets.only(bottom: 15.0, right: 15.0, left: 15.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: widget.onTap != null ? () => widget.onTap!(context) : null,
            child: Padding(
              padding: EdgeInsets.only(
                top: 5,
                bottom: 5,
              ),
              child: ListTile(
                title: Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Text(
                    widget.sectionCode,
                    style: TextStyle(
                        fontSize: 17,
                        color: Colors.black,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          widget.classes.name ?? '', // 수업 이름을 추가합니다.
                          maxLines: 1, // 최대 라인을 한 줄로 제한합니다.
                          overflow:
                              TextOverflow.ellipsis, // 긴 텍스트는 ...으로 생략되게 합니다.
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.black), // 원하는 스타일을 적용합니다.
                        ),
                      ),
                      SizedBox(
                        height: 2,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          widget.instructorName,
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(
                        height: 2,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          widget.meetingTimes,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 3, top: 2),
                        child: seatButton(
                            'Seats: ${widget.fullSeat.toString()}' +
                                ",  "
                                    'Open Seats: ${widget.openSeat.toString()}' +
                                ",  "
                                    'Waitlist: ${widget.waitlist.toString()}' +
                                ",  "
                                    'Holdfile: ${widget.holdfile.toString()}',
                            Colors.white.withOpacity(0.7),
                            () {}),
                      ),
                    ],
                  ),
                ),
                trailing: GestureDetector(
                  onTap: widget.onPressed == null || check
                      ? null
                      : () {
                          widget.onPressed!(context);
                          setState(() {
                            check = !check; // 상태 변경
                            //widget.onIconToggled?.call(); // 콜백 호출
                          });
                        },
                  child: Icon(
                    check ? widget.toggledIcon ?? Icons.check : widget.icon,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
