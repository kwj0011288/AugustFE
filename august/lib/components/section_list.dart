import 'package:flutter/material.dart';
import '../get_api/timetable/schedule.dart';

class SectionTile extends StatefulWidget {
  final ScheduleList classes;
  final void Function(BuildContext context)? onPressed;
  final void Function(BuildContext context)? onTap;
  final IconData icon;
  final IconData? toggledIcon;
  final Function? onIconToggled;
  final Color backgroundColor;

  // 네임드 파라미터를 사용하고 onPressed와 onTap을 nullable로 변경
  const SectionTile({
    Key? key,
    required this.classes,
    this.onPressed,
    this.onTap,
    required this.icon,
    this.toggledIcon,
    this.onIconToggled,
    required this.backgroundColor,
  }) : super(key: key);

  @override
  _SectionTileState createState() => _SectionTileState();
}

class _SectionTileState extends State<SectionTile> {
  bool check = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 15.0, right: 15.0, left: 15.0),
      child: GestureDetector(
        onTap: widget.onTap != null ? () => widget.onTap!(context) : null,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30, horizontal: 5),
          child: ListTile(
            title: RichText(
              text: TextSpan(children: [
                TextSpan(
                    text:
                        '${widget.classes.courseCode ?? ''}-${widget.classes.sectionCode ?? ''}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                for (var meeting in widget.classes.meetings!)
                  TextSpan(
                      text:
                          '\n${meeting.days} ${meeting.startTime}-${meeting.endTime} at ${meeting.building}-${meeting.room}')
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
