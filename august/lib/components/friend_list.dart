import 'package:august/components/button.dart';
import 'package:august/const/background_color.dart';
import 'package:august/const/dark_theme.dart';
import 'package:august/const/light_theme.dart';
import 'package:august/const/tile_color.dart';
import 'package:august/login/initialpage.dart';
import 'package:august/pages/homepage.dart';
import 'package:august/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import '../get_api/class.dart';
import 'package:animations/animations.dart';

class FriendsList extends StatefulWidget {
  final void Function(BuildContext context)? onTap;
  final IconData icon;
  final IconData? toggledIcon;
  final Function? onIconToggled;
  final Color backgroundColor;
  final int index;

  // 네임드 파라미터를 사용하고 onPressed와 onTap을 nullable로 변경
  const FriendsList({
    Key? key,
    this.onTap,
    required this.icon,
    this.toggledIcon,
    this.onIconToggled,
    required this.backgroundColor,
    required this.index,
  }) : super(key: key);

  @override
  _FriendsListState createState() => _FriendsListState();
}

class _FriendsListState extends State<FriendsList> {
  bool check = false;

  Widget buildButton(String text, Color buttonColor, final VoidCallback onTap) {
    TextStyle buttonTextStyle = TextStyle(
      // Define your text style here
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    double textWidth = calculateTextWidth(text, buttonTextStyle, context);
    double buttonWidth = textWidth + 10; // Add some padding to the text width

    return Container(
      width: buttonWidth,
      height: 30,
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.circular(40),
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
                  fontSize: 15,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: OpenContainer(
        closedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        closedColor: Theme.of(context).colorScheme.background,
        closedBuilder: (BuildContext context, VoidCallback openContainer) {
          return GestureDetector(
            onTap: openContainer,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                // borderRadius: BorderRadius.circular(30),
              ),
              child: ListTile(
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 5),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey,
                          foregroundColor:
                              Theme.of(context).colorScheme.background,
                          backgroundImage: null,
                          maxRadius: 25,
                          child: Icon(Icons.person, size: 40),
                        ),
                        SizedBox(width: 10),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Name",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.outline),
                            ),
                            Text(
                              "11 credits",
                              style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      Colors.grey.shade400), // 원하는 스타일을 적용합니다.
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        buildButton("Freshman", Color(0xFFffe6ea), () {}),
                        SizedBox(width: 10),
                        buildButton("CMSC", Color(0xFFe3ecff), () {}),
                      ],
                    ),
                    SizedBox(height: 5),
                  ],
                ),
                trailing: GestureDetector(
                  onTap: () {},
                  child: Icon(
                    check ? widget.toggledIcon ?? Icons.check : widget.icon,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ),
          );
        },
        openBuilder: (BuildContext context, VoidCallback _) {
          return SplashScreen(); // 여기에서 새 페이지로 이동합니다.
        },
        transitionDuration: Duration(milliseconds: 500), // 전환 시간 설정
        // 다른 OpenContainer 설정들을 추가할 수 있습니다.
      ),
    );
  }
}

/* 
Dummy data
[
  {
    "name": "Fearless First: Negotiating the Hidden Curriculum in Higher Education and Other Societal Institutions",
    "course_code": "AAPS380",
    "credits": 2,
    "sections_by_instructor": [
      {
        "name": "Sharon Vanwright",
        "sections": [
          {
            "id": 8029,
            "section_code": "AAPS380-0101",
            "instructors": [
              "Sharon Vanwright"
            ],
            "meetings": [
              {
                "building": "KEY",
                "room": "0103",
                "days": "W",
                "start_time": "16:00",
                "end_time": "17:45"
              }
            ]
          },
          {
            "id": 8030,
            "section_code": "AAPS380-0102",
            "instructors": [
              "Sharon Vanwright"
            ],
            "meetings": [
              {
                "building": "KEY",
                "room": "0110",
                "days": "F",
                "start_time": "10:00",
                "end_time": "11:45"
              }
            ]
          }
        ]
      },
      {
        "name": "Michael Johnson",
        "sections": [
          {
            "id": 8031,
            "section_code": "AAPS380-0201",
            "instructors": [
              "Michael Johnson"
            ],
            "meetings": [
              {
                "building": "SCI",
                "room": "0240",
                "days": "T",
                "start_time": "13:00",
                "end_time": "14:45"
              }
            ]
          }
        ]
      },
      {
        "name": "Linda Eastman",
        "sections": [
          {
            "id": 8032,
            "section_code": "AAPS380-0301",
            "instructors": [
              "Linda Eastman"
            ],
            "meetings": [
              {
                "building": "LIB",
                "room": "1002",
                "days": "M",
                "start_time": "08:00",
                "end_time": "09:45"
              }
            ]
          }
        ]
      }
    ]
  }
]
*/