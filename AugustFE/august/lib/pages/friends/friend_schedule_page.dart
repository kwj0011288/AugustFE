import 'dart:convert';
import 'dart:math';

import 'package:august/components/friends/friend_button.dart';
import 'package:august/components/home/loading.dart';
import 'package:august/components/timetable/timetable.dart';
import 'package:august/const/tile_color.dart';
import 'package:august/get_api/friends/friend_table.dart';
import 'package:august/get_api/friends/friends_sem.dart';
import 'package:august/get_api/friends/hangout.dart';
import 'package:august/get_api/onboard/get_semester.dart';
import 'package:august/get_api/timetable/schedule.dart';
import 'package:august/login/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import "package:flutter_feather_icons/flutter_feather_icons.dart";
import 'package:shared_preferences/shared_preferences.dart';

class FriendSchedulePage extends StatefulWidget {
  final String? photoUrl; // 사진 URL
  final String name; // 친구 이름
  final String yearInSchool;
  final String department;
  // final List<int>? semesterList;
  final int? friendId;

  const FriendSchedulePage({
    Key? key,
    this.photoUrl,
    required this.name,
    required this.yearInSchool,
    required this.department,
    //   this.semesterList,
    this.friendId,
  }) : super(key: key);

  @override
  State<FriendSchedulePage> createState() => _FriendSchedulePageState();
}

class _FriendSchedulePageState extends State<FriendSchedulePage>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  bool schedule1 = true;
  bool schedule2 = false;
  int? selectedSemester;
  int? numberOfClasses = 0;
  bool isLoading = false;

  List<int>? friendSemList;
  List<ScheduleList> scheduleLists = [];
  List<ScheduleList> chillLists = [];

  String formatSemester(String semester) {
    String year = semester.substring(0, 4);
    String season = getSeasonFromSemester(semester);
    return "$season $year";
  }

  @override
  void initState() {
    super.initState();
    // selectedSemester = friendSemList!.last;
    // selectedSemester = widget.semesterList!.last;
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _animationController!.forward();

    checkAndLoad();
  }

  void checkAndLoad() async {
    // Perform an asynchronous check for an access token and then load data accordingly
    await checkAccessToken();
    print('token refreshed');

    // Assuming `selectedSemester` and `loadTimetable` logic is correctly handled elsewhere and available here
    // if (selectedSemester != null) {
    //   loadTimetable(widget.friendId!, selectedSemester!);
    //   _loadHangout(selectedSemester!);
    // }

    _loadSemesters();
  }

  Future<void> _loadSemesters() async {
    if (widget.friendId != null) {
      try {
        var semesters =
            await FriendSemester().fetchFriendSemester(widget.friendId!);

        setState(() {
          friendSemList = semesters;
          if (friendSemList != null && friendSemList!.isNotEmpty) {
            selectedSemester =
                friendSemList!.last; // Update selected semester after loading
            loadTimetable(widget.friendId!,
                selectedSemester!); // Load timetable after setting the semester
            _loadHangout(selectedSemester!);
          }
        });
      } catch (e) {
        print("Failed to load semesters: $e");
      }
    }
  }

  Future<void> _loadHangout(semester) async {
    await checkAccessToken();
    setState(() {
      isLoading = true; // Start loading
    });
    if (widget.friendId != null) {
      try {
        ScheduleList hangoutList =
            await HangoutRequest().fetchHangout(widget.friendId!, semester);
        setState(() {
          chillLists.clear();
          chillLists.add(hangoutList);
          isLoading = false;
        });
      } catch (e) {
        print("Failed to load semesters: $e");
      }
    }
  }

  void loadTimetable(int friendId, int semester) async {
    await checkAccessToken();
    setState(() {
      isLoading = true; // Start loading
    });

    FriendTimeTable friendTimeTable = FriendTimeTable();
    try {
      var schedules =
          await friendTimeTable.fetchFriendTimetable(friendId, semester);
      setState(() {
        scheduleLists = schedules;
        numberOfClasses = schedules.length;
        isLoading = false; // Stop loading after data is fetched
      });
    } catch (e) {
      // Log error or show an error message on the UI
      print('Error fetching schedule: $e');
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("Error"),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: Text("OK"),
            ),
          ],
        ),
      );
      setState(() {
        isLoading = false; // Stop loading if an error occurs
      });
    }
  }

  @override
  void dispose() {
    _animationController!.dispose();
    super.dispose();
  }

  void _selectFriendsSem(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(40.0),
      ),
      context: context,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(40)),
          child: Container(
            margin: EdgeInsets.only(bottom: 20),
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width - 20,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.all(Radius.circular(40)),
            ),
            child: Padding(
              padding: EdgeInsets.only(left: 30, right: 20, top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 0),
                        child: Text(
                          "Select Semester",
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                        },
                        child: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.background,
                          child: Center(
                            child: Icon(
                              FeatherIcons.x,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.only(top: 10),
                      shrinkWrap: true,
                      itemCount: friendSemList!.length,
                      itemBuilder: (context, index) {
                        int semester = friendSemList![index];
                        String formattedSemester =
                            formatSemester(semester.toString());
                        bool isSelected = selectedSemester ==
                            semester; // Check if it's the selected semester

                        return ListTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formattedSemester,
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.outline
                                        : makeDarker(
                                            Theme.of(context)
                                                .colorScheme
                                                .outline,
                                            0.3)),
                              ),
                            ],
                          ),
                          trailing: isSelected
                              ? const Icon(FeatherIcons.check,
                                  color: Colors.green)
                              : null,
                          onTap: () {
                            if (semester != selectedSemester) {
                              // Check if the tapped semester is different
                              setState(() {
                                selectedSemester = semester;
                                isLoading = true;
                              });
                              loadTimetable(widget.friendId!,
                                  semester); // Reload timetable
                              _loadHangout(semester);
                            }
                            Navigator.pop(context); // Close the modal sheet
                          },
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
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
                            buildButton(
                                '$numberOfClasses Courses',
                                Color(0xFFffe6ea),
                                () {},
                                Colors.black,
                                FontWeight.w400,
                                context),
                            SizedBox(
                              height: 10,
                            ),
                            buildButton(
                                (widget.yearInSchool),
                                Color(0xFFe5fff9),
                                () {},
                                Colors.black,
                                FontWeight.w400,
                                context),
                            SizedBox(
                              height: 10,
                            ),
                            buildButton(widget.department, Color(0xFFe3ecff),
                                () {}, Colors.black, FontWeight.w400, context),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 20, top: 10, bottom: 10, left: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            GestureDetector(
                                onTap: () {
                                  checkAccessToken();
                                  _selectFriendsSem(context);
                                },
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 200),
                                  child: AnimatedOpacity(
                                    duration: Duration(milliseconds: 200),
                                    opacity:
                                        selectedSemester != null ? 1.0 : 0.0,
                                    child: Row(
                                      children: [
                                        Text(
                                          selectedSemester != null
                                              ? formatSemester(
                                                  selectedSemester.toString())
                                              : '',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Icon(
                                          selectedSemester != null
                                              ? Icons.keyboard_arrow_down
                                              : null,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                )),
                            Spacer(),
                            buildButton(
                                'Schedule',
                                schedule1
                                    ? Colors.blueAccent.shade400
                                    : Colors.grey.shade700, () {
                              HapticFeedback.mediumImpact();
                              setState(() {
                                schedule1 = true;
                                schedule2 = false;
                              });
                            }, Colors.white, FontWeight.bold, context),
                            SizedBox(width: 10),
                            buildButton(
                                'Hang out',
                                schedule2
                                    ? Colors.blueAccent.shade400
                                    : Colors.grey.shade700, () {
                              HapticFeedback.mediumImpact();
                              setState(() {
                                schedule1 = false;
                                schedule2 = true;
                              });
                            }, Colors.white, FontWeight.bold, context),
                          ],
                        ),
                      ),

                      // 기존의 Column 위젯을 AnimatedSwitcher로 감싸서 애니메이션 효과 추가
                      AnimatedSwitcher(
                        duration: const Duration(
                            milliseconds:
                                300), // Adjust duration for visual effect
                        child: scheduleLists.isEmpty || isLoading
                            ? Center(
                                child: GroupLoading4(
                                    context)) // Show loading indicator if empty
                            : (schedule1
                                ? Column(
                                    children: [
                                      Text(
                                        'This is ${widget.name}\'s schedule.',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      SingleTimetable(
                                        key: ValueKey<int>(
                                            1), // Unique key for AnimatedSwitcher when showing schedule
                                        courses: scheduleLists,
                                        index: 0,
                                        forceFixedTimeRange: true,
                                      ),
                                    ],
                                  )
                                : (chillLists.first.meetings == null)
                                    ? Column(
                                        children: [
                                          Text(
                                            'No chill time available',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          ...List.generate(
                                            3,
                                            (index) => Padding(
                                              padding:
                                                  const EdgeInsets.all(2.0),
                                              child: Text(
                                                '.',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'Maybe',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            'you or ${widget.name} did not setup schedule yet?',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          )
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          Text(
                                            '${widget.name} and you can hang out at these times!',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          SingleTimetable(
                                            key: ValueKey<int>(
                                                2), // Unique key for AnimatedSwitcher when showing chill lists
                                            courses: chillLists,
                                            index: 0,
                                            forceFixedTimeRange: true,
                                            isFriend: true,
                                          ),
                                        ],
                                      )),
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
