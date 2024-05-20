import 'package:august/components/button.dart';
import 'package:august/const/background_color.dart';
import 'package:august/const/dark_theme.dart';
import 'package:august/const/light_theme.dart';
import 'package:august/const/tile_color.dart';
import 'package:flutter/material.dart';
import '../get_api/class.dart';

class SearchTile extends StatefulWidget {
  final CourseList classes;
  final String sectionCode;
  final String instructorName;
  final String meetingTimes;
  final int fullSeat;
  final int openSeat;
  final int waitlist;

  final void Function(BuildContext context)? onTap;
  final Function? onIconToggled;
  final Color backgroundColor;
  final int index;

  // 네임드 파라미터를 사용하고 onPressed와 onTap을 nullable로 변경
  const SearchTile({
    Key? key,
    required this.classes,
    this.onTap,
    this.onIconToggled,
    required this.backgroundColor,
    required this.index,
    required this.sectionCode,
    required this.instructorName,
    required this.meetingTimes,
    required this.fullSeat,
    required this.openSeat,
    required this.waitlist,
  }) : super(key: key);

  @override
  _SearchTileState createState() => _SearchTileState();
}

class _SearchTileState extends State<SearchTile> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    List<Color> tileColors =
        theme.brightness == Brightness.dark ? tileColorsDark : tileColorsLight;
    return Container(
      decoration: BoxDecoration(
        color: tileColors[widget.index % tileColors.length],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow,
            blurRadius: 10,
            offset: Offset(4, 8),
          )
        ],
      ),
      margin: const EdgeInsets.only(bottom: 15.0, right: 15.0, left: 15.0),
      child: InkWell(
        onTap: widget.onTap != null ? () => widget.onTap!(context) : null,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 2),
                      Text(
                        widget.sectionCode,
                        style: TextStyle(
                            fontSize: 17,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        (widget.classes.name ?? '').length > 30
                            ? '${(widget.classes.name ?? '').substring(0, 30)}...'
                            : (widget.classes.name ?? ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      SizedBox(height: 2),
                      Text(
                        widget.instructorName,
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        widget.meetingTimes,
                        style: TextStyle(fontSize: 12, color: Colors.black),
                      ),
                      SizedBox(height: 2),
                    ],
                  ),
                ),
              ),
              Container(
                width: 100, // 너비 조절
                height: 90, // 높이 조절
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // 수직 방향 중앙 정렬
                    children: [
                      Center(
                        child: Text(
                          'Seats: ${widget.fullSeat}\nOpen Seats: ${widget.openSeat}\nWaitlist: ${widget.waitlist}',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
