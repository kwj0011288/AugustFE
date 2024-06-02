import 'package:august/login/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:august/get_api/onboard/get_department.dart'; // Make sure this import is correct
import "package:flutter_feather_icons/flutter_feather_icons.dart";
import 'package:flutter_svg/svg.dart';

class MajorPage extends StatefulWidget {
  final bool onboard;
  final VoidCallback goBack;
  final VoidCallback gonext;
  List<String> preloadedDepartments;
  MajorPage({
    Key? key,
    required this.onboard,
    required this.preloadedDepartments,
    required this.goBack,
    required this.gonext,
  }) : super(key: key);

  @override
  _MajorPageState createState() => _MajorPageState();
}

class _MajorPageState extends State<MajorPage> {
  String? _selectedMajor;
  String? _selectedMajorFullname;
  String? _selectedMajorNickname;
  int? _selectedMajorIndex;

  @override
  void initState() {
    super.initState();
    // Print the preloaded departments to the console
    print("Preloaded Departments: ${widget.preloadedDepartments}");

    if (widget.preloadedDepartments.isEmpty) {
      // If the preloaded departments list is empty, fetch the departments
      fetchDepartments().then((departments) {
        setState(() {
          widget.preloadedDepartments = departments;
        });
      });
    }
  }

  Future<void> _selectMajor(String selectedDept) async {
    // 선택된 항목 문자열을 분석하여 ID, 전체 이름, 별명 추출
    // 예상 형식: "ID: 1, Computer Science (CMSC)"
    final parts = selectedDept.split(', ');
    final idPart = parts[0];
    final fullnameAndNickname = parts.sublist(1).join(", "); // ID 이후 부분 재조합
    final fullName = fullnameAndNickname.split(" (")[0];
    final nickname = fullnameAndNickname.contains("(")
        ? fullnameAndNickname.split(" (")[1].replaceAll(")", "")
        : '';

    // ID 추출
    final id = int.tryParse(idPart.split(': ')[1]) ?? -1;

    setState(() {
      _selectedMajorIndex = id;
      _selectedMajorFullname = fullName;
      _selectedMajorNickname = nickname;
      _selectedMajor = "$fullName ($nickname)"; // UI에 표시될 문자열 업데이트
    });

    // 선택된 전공의 fullname 출력 (디버깅 목적)
    if (_selectedMajorFullname != null) {
      print('Selected Major Fullname: $_selectedMajorFullname');
      print('$_selectedMajorIndex');
    }
  }

  Future<void> _loadInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Check if the semester value is in the semestersList

    setState(() {
      _selectedMajorNickname = prefs.getString('major');
    });
  }

  Future<void> _saveInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setString('major', _selectedMajorNickname ?? '');
  }

  Future<void> _saveAndClose() async {
    checkAccessToken();
    _saveInfo();
    Map<String, dynamic> userInfo = {'major': _selectedMajorNickname};

    widget.onboard ? null : Navigator.pop(context, userInfo);
    int? userPk = await fetchUserPk();

    if (userPk == null) {
      print("Failed to fetch userPk");
      return;
    }

    if (_selectedMajorIndex != null && _selectedMajorIndex! >= 0) {
      // 백그라운드에서 updateDepartment 호출
      Future<void> updateFuture =
          updateDepartment(userPk, _selectedMajorIndex!);
      updateFuture.then((_) {
        print('Department updated successfully');
      }).catchError((error) {
        print('Failed to update department: $error');
      });
    } else {
      print('Invalid or missing major index');
      // 오류 처리 로직
      return; // 유효하지 않은 경우 함수 종료
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor:
            widget.onboard ? Colors.transparent : Colors.transparent,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacer(),
            Padding(
              padding: const EdgeInsets.only(
                  top: 0, left: 10, right: 10, bottom: 25),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.onboard
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.background,
                  borderRadius:
                      BorderRadius.all(Radius.circular(30)), // 모서리를 둥글게 만듭니다.
                  // 필요하다면 여기에 그림자나 테두리 등을 추가할 수 있습니다.
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20), // 상단 왼쪽 모서리 둥글게
                            topRight: Radius.circular(20), // 상단 오른쪽 모서리 둥글게
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            heightFactor:
                                0.8, // 이미지의 상위 80%만 보여줍니다. 하단 20%는 잘립니다.
                            child: SvgPicture.asset(
                              'assets/icons/major.svg',
                              width: MediaQuery.of(context).size.width,
                              // height 설정을 제거하여 전체 이미지 높이를 기준으로 잘립니다.
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 10, bottom: 80),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (widget.onboard == false)
                                Container(
                                  height: 30,
                                  width: 30,
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    shape: BoxShape
                                        .circle, // Ensures the container is circular
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      FeatherIcons.x,
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                      size: 20,
                                    ),

                                    onPressed: () {
                                      if (Navigator.canPop(context)) {
                                        Navigator.pop(context);
                                      }
                                    },
                                    padding: EdgeInsets.all(
                                        5), // Remove padding to fit the icon well
                                    constraints:
                                        BoxConstraints(), // Remove constraints if necessary
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                      "Select Major",
                      style: TextStyle(
                        fontSize: 25,
                        color: Theme.of(context).colorScheme.outline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "Selected Semester is used for\nCourse search, Schedule Creation, and sharing schedules with friends.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      child: Form(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PullDownButton(
                              itemBuilder: (BuildContext context) {
                                return widget.preloadedDepartments.map((dept) {
                                  final parts = dept.split(', ');
                                  final fullnameAndNickname = parts
                                      .sublist(1)
                                      .join(", "); // ID 이후 부분 재조합
                                  final fullname =
                                      fullnameAndNickname.split(" (")[0];
                                  final nickname =
                                      fullnameAndNickname.contains("(")
                                          ? fullnameAndNickname
                                              .split(" (")[1]
                                              .replaceAll(")", "")
                                          : '';
                                  final displayFullName = fullname;
                                  final displayNickName = nickname;

                                  return PullDownMenuItem(
                                    title: displayNickName,
                                    onTap: () => _selectMajor(dept),
                                    subtitle: displayFullName,
                                  );
                                }).toList();
                              },
                              buttonBuilder: (BuildContext context,
                                  Future<void> Function() showMenu) {
                                return Container(
                                  decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .inversePrimary,
                                      borderRadius: BorderRadius.circular(15)),
                                  child: TextButton(
                                    onPressed: showMenu,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 50, vertical: 5),
                                      child: Text(
                                        _selectedMajorNickname ??
                                            "Select Major",
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              scrollController: ScrollController(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    widget.onboard
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  widget.goBack();
                                  _saveAndClose();
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  height: 55,
                                  width: MediaQuery.of(context).size.width / 3,
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.redAccent, width: 2),
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(60)),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'BACK',
                                        style: TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  widget.gonext();
                                  _saveAndClose();
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  height: 55,
                                  width: MediaQuery.of(context).size.width / 3,
                                  decoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      borderRadius: BorderRadius.circular(60)),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'NEXT',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : GestureDetector(
                            onTap: () {
                              _saveAndClose();
                              HapticFeedback.mediumImpact();
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 30),
                              height: 55,
                              width: MediaQuery.of(context).size.width - 80,
                              decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  borderRadius: BorderRadius.circular(60)),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'DONE',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
