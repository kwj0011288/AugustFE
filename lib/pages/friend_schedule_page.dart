import 'dart:math';

import 'package:august/components/button.dart';
import 'package:august/components/timetable.dart';
import 'package:august/get_api/schedule.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import "package:flutter_feather_icons/flutter_feather_icons.dart";

class FriendSchedulePage extends StatefulWidget {
  final String? photoUrl; // 사진 URL
  final String name; // 친구 이름

  const FriendSchedulePage({
    Key? key,
    this.photoUrl,
    required this.name,
  }) : super(key: key);

  @override
  State<FriendSchedulePage> createState() => _FriendSchedulePageState();
}

class _FriendSchedulePageState extends State<FriendSchedulePage>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  bool schedule1 = true;
  bool schedule2 = false;
  bool schedule3 = false;

  List<ScheduleList> scheduleLists = [];
  List<ScheduleList> chillLists = [];

  final List<Map<String, dynamic>> jsonData = [
    // 시간표 1
    {
      // 시간표 1에 포함된 수업 1
      "id": 123,
      "name": "Anatomy of Domestic Animals",
      "course_code": "ANSC204",
      "section_code": "ANSC204-0101",
      "instructors": ["Angela Black"],
      "meetings": [
        {
          "building": "ANS",
          "room": "0408",
          "days": "M",
          "start_time": "14:00",
          "end_time": "14:50"
        },
        {
          "building": "ANS",
          "room": "0408",
          "days": "W",
          "start_time": "14:00",
          "end_time": "14:50"
        }
      ],
      "credits": 2,
      "seats": 50,
      "open_seats": 35,
      "waitlist": 0,
      "holdfile": null
    },
    {
      // 시간표 1에 포함된 수업 2
      "id": 456,
      "name": "Introduction to Plant Biology",
      "course_code": "BIOL101",
      "section_code": "BIOL101-0202",
      "instructors": ["Christopher Green"],
      "meetings": [
        {
          "building": "BIO",
          "room": "0203",
          "days": "T",
          "start_time": "10:00",
          "end_time": "11:15"
        },
        {
          "building": "BIO",
          "room": "0203",
          "days": "Th",
          "start_time": "10:00",
          "end_time": "11:15"
        }
      ],
      "credits": 3,
      "seats": 60,
      "open_seats": 40,
      "waitlist": 5,
      "holdfile": null
    }
  ];
  final List<Map<String, dynamic>> jsonData1 = [
    // 시간표 1
    {
      // 시간표 1에 포함된 수업 1
      "id": 123,
      "name": "Anatomy of Domestic Animals",
      "course_code": "Chill",
      "section_code": "ANSC204-0101",
      "instructors": ["Angela Black"],
      "meetings": [
        {
          "building": "ANS",
          "room": "0408",
          "days": "M",
          "start_time": "7:00",
          "end_time": "14:50"
        },
        {
          "building": "ANS",
          "room": "0408",
          "days": "W",
          "start_time": "14:00",
          "end_time": "14:50"
        }
      ],
      "credits": 2,
      "seats": 50,
      "open_seats": 35,
      "waitlist": 0,
      "holdfile": null
    },
    {
      // 시간표 1에 포함된 수업 2
      "id": 456,
      "name": "Introduction to Plant Biology",
      "course_code": "BIOL101",
      "section_code": "BIOL101-0202",
      "instructors": ["Christopher Green"],
      "meetings": [
        {
          "building": "BIO",
          "room": "0203",
          "days": "T",
          "start_time": "8:00",
          "end_time": "11:15"
        },
        {
          "building": "BIO",
          "room": "0203",
          "days": "Th",
          "start_time": "10:00",
          "end_time": "11:15"
        }
      ],
      "credits": 3,
      "seats": 60,
      "open_seats": 40,
      "waitlist": 5,
      "holdfile": null
    }
  ];
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _animationController!.forward();
    //demo 데이터
    scheduleLists =
        jsonData.map((data) => ScheduleList.fromJson(data)).toList();

    chillLists = jsonData1.map((data) => ScheduleList.fromJson(data)).toList();
  }

  @override
  void dispose() {
    _animationController!.dispose();
    super.dispose();
  }

  Widget buildButton(String text, Color buttonColor, final VoidCallback onTap,
      Color textColor, FontWeight textWeight) {
    TextStyle buttonTextStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    double textWidth = calculateTextWidth(text, buttonTextStyle, context);
    double buttonWidth = textWidth + 10; // Add some padding to the text width

    // AnimatedContainer for background color animation
    return AnimatedContainer(
      duration: Duration(milliseconds: 200), // Duration of the animation
      width: buttonWidth,
      height: 30,
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow,
            blurRadius: 10,
            offset: Offset(6, 4),
          ),
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow,
            blurRadius: 10,
            offset: Offset(-2, 0),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Center(
            // AnimatedSwitcher for text change animation
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Text(
                text,
                key: ValueKey<String>(text), // Unique key for AnimatedSwitcher
                style: TextStyle(
                    color: textColor, fontSize: 15, fontWeight: textWeight),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 10, left: 10, bottom: 10),
                    child: Row(
                      children: [
                        AnimatedBuilder(
                          animation: _animationController!,
                          builder: (context, child) {
                            return Transform(
                              transform: Matrix4.identity()
                                ..translate(0.0, 5.0), // 위치 조정
                              child: Container(
                                padding: EdgeInsets.all(10), // 내부 여백 추가
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Theme.of(context).colorScheme.shadow,
                                      blurRadius: 10,
                                      offset: Offset(6, 4),
                                    ),
                                    BoxShadow(
                                      color:
                                          Theme.of(context).colorScheme.shadow,
                                      blurRadius: 10,
                                      offset: Offset(-2, 0),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 80, // 이미지의 가로 크기를 80으로 설정
                                      height: 80, // 이미지의 세로 크기를 80으로 설정
                                      child: ClipOval(
                                        child: widget.photoUrl != null
                                            ? Image.network(widget.photoUrl!,
                                                fit: BoxFit.cover)
                                            : Icon(Icons.person,
                                                size: 80), // 기본 아이콘 표시
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(widget.name,
                                        style:
                                            TextStyle(fontSize: 15)), // 이름 표시
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 10,
                            ),
                            buildButton('6 Courses', Color(0xFFffe6ea), () {},
                                Colors.black, FontWeight.w400),
                            SizedBox(
                              height: 10,
                            ),
                            buildButton(('Sophomore'), Color(0xFFe5fff9), () {},
                                Colors.black, FontWeight.w400),
                            SizedBox(
                              height: 10,
                            ),
                            buildButton('CMSC', Color(0xFFe3ecff), () {},
                                Colors.black, FontWeight.w400),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 15),
                  //   child: Divider(
                  //     color: Colors.grey.shade500,
                  //   ),
                  // ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 20, top: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            buildButton(
                              'Friends Schedule',
                              schedule1
                                  ? Colors.blueAccent.shade400
                                  : Colors.grey.shade700,
                              () {
                                HapticFeedback.mediumImpact();
                                setState(() {
                                  schedule1 = true;
                                  schedule2 = false;
                                  schedule3 = false;
                                });
                              },
                              Colors.white,
                              FontWeight.bold,
                            ),
                            SizedBox(width: 10),
                            buildButton(
                              'Chill Together',
                              schedule2
                                  ? Color.fromARGB(255, 81, 108, 136)
                                  : Colors.grey.shade700,
                              () {
                                HapticFeedback.mediumImpact();
                                setState(() {
                                  schedule1 = false;
                                  schedule2 = true;
                                  schedule3 = false;
                                });
                              },
                              Colors.white,
                              FontWeight.bold,
                            ),
                            SizedBox(width: 10),
                            GestureDetector(
                              child: Container(
                                width: 30.0, // 원하는 크기 설정
                                height: 30.0, // 원하는 크기 설정
                                decoration: BoxDecoration(
                                    color: schedule3
                                        ? Color.fromARGB(255, 81, 124, 136)
                                        : Colors.grey.shade700,
                                    borderRadius: BorderRadius.circular(30)),
                                child: Center(
                                  child: Icon(
                                    FeatherIcons.type,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                setState(() {
                                  schedule1 = false;
                                  schedule2 = false;
                                  schedule3 = true;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      // 기존의 Column 위젯을 AnimatedSwitcher로 감싸서 애니메이션 효과 추가
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 0),
                        child: schedule3
                            ? Container(
                                margin: EdgeInsets.only(
                                    top: 10, left: 10, right: 10),
                                padding: EdgeInsets.all(10), // 내부 여백 추가
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Theme.of(context).colorScheme.shadow,
                                      blurRadius: 10,
                                      offset: Offset(6, 4),
                                    ),
                                    BoxShadow(
                                      color:
                                          Theme.of(context).colorScheme.shadow,
                                      blurRadius: 10,
                                      offset: Offset(-2, 0),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "Same Courses",
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      "1. CMSC335\n2. CMSC330\n3. CMSC351",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      "Time to chill together",
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "10:00 ~ 10:50 AM\n3:00 ~ 5:00 PM",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                key: ValueKey<int>(3),
                              ) // Unique key for AnimatedSwitcher
                            : schedule1
                                ? SingleTimetable(
                                    key: ValueKey<int>(
                                        1), // Unique key for AnimatedSwitcher
                                    courses: scheduleLists,
                                    index: 0,
                                  )
                                : SingleTimetable(
                                    key: ValueKey<int>(
                                        2), // Unique key for AnimatedSwitcher
                                    courses: chillLists,
                                    index: 0,
                                  ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Builder(
                builder: (BuildContext innerContext) {
                  return Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(innerContext).colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.shadow,
                          blurRadius: 10,
                          offset: Offset(6, 4),
                        ),
                        BoxShadow(
                          color: Theme.of(context).colorScheme.shadow,
                          blurRadius: 10,
                          offset: Offset(-2, 0),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        FeatherIcons.x,
                        color: Theme.of(innerContext).colorScheme.outline,
                        size: 25,
                      ),
                      onPressed: () {
                        Navigator.pop(innerContext);
                      },
                      padding: EdgeInsets.all(5),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
