import 'package:august/components/button.dart';
import 'package:august/components/courseprovider.dart';
import 'package:august/get_api/get_semester.dart';
import 'package:august/get_api/get_univ.dart';
import 'package:august/login/login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pull_down_button/pull_down_button.dart';
import "package:flutter_feather_icons/flutter_feather_icons.dart";

class UnivPage extends StatefulWidget {
  final bool onboard;
  final VoidCallback goBack;
  final VoidCallback gonext;
  UnivPage({
    Key? key,
    required this.onboard,
    required this.goBack,
    required this.gonext,
  }) : super(key: key);

  @override
  _UnivPageState createState() => _UnivPageState();
}

class _UnivPageState extends State<UnivPage> {
  String? _selectedSchoolFullname;
  String? _selectedSchoolNickname;
  int? _selectedSchoolIndex;
  List<Institution> schoolsList = []; // Updated to hold Institution objects

  late Future<void> _loadUserFuture;

  late List<String> semestersList = [];
  late String currentSemester = '';

  final FocusNode _schoolFocusNode = FocusNode();

  @override
  void dispose() {
    super.dispose();
  }

// initState에서 _loadInfo 호출
  @override
  void initState() {
    super.initState();

    fetchInstitutions().then((loadedInstitutions) {
      setState(() {
        schoolsList = loadedInstitutions;
      });
    });
    if (semestersList.isNotEmpty) {
      currentSemester = semestersList[0];
    }
    _loadUserFuture = _loadInfo();
  }

  Future<void> _loadInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? semester = prefs.getString('semester');
    if (!semestersList.contains(semester)) {
      semester = semestersList.isNotEmpty ? semestersList[0] : null;
    }
    setState(() {
      _selectedSchoolFullname = prefs.getString('fullname');
      _selectedSchoolNickname = prefs.getString('nickname');
      _selectedSchoolIndex = prefs.getInt('schoolId'); // id를 불러옵니다.
    });
  }

  Future<void> _saveInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('fullname', _selectedSchoolFullname ?? '');
    prefs.setString('nickname', _selectedSchoolNickname ?? '');
    if (_selectedSchoolIndex != null) {
      // id가 있을 경우에만 저장합니다.
      prefs.setInt('schoolId', _selectedSchoolIndex!);
    }
  }

// 'Done' 버튼이 클릭될 때 _saveInfo 호출
  Future<void> _saveAndClose() async {
    checkAccessToken();
    await _saveInfo();
    Map<String, dynamic> userInfo = {
      'fullname': _selectedSchoolFullname,
      'nickname': _selectedSchoolNickname,
      'id': _selectedSchoolIndex, // 사용자 정보에 id를 추가합니다.
    };
    widget.onboard ? null : Navigator.pop(context, userInfo);
    int? userPk = await fetchUserPk();

    if (userPk == null) {
      print("Failed to fetch userPk");
      return;
    }

    if (_selectedSchoolFullname!.isNotEmpty && _selectedSchoolIndex != null) {
      // updateInstitution을 백그라운드에서 호출
      updateInstitution(userPk, _selectedSchoolIndex!).then((_) {
        print('Institution updated successfully');
      }).catchError((error) {
        print('Failed to update institution: $error');
      });
    }

    // 바로 다음 화면으로 넘어가거나 현재 화면을 닫음
  }

  void _onSchoolChanged(String? value) {
    var selectedInstitution = schoolsList.firstWhere(
      (institution) => institution.fullName == value,
    );
    setState(() {
      _selectedSchoolFullname = value;
      if (selectedInstitution != null) {
        _selectedSchoolNickname = selectedInstitution.nickname;
        _selectedSchoolIndex = selectedInstitution.id; // 선택한 기관의 id를 저장합니다.

        print('Selected School Fullname: $_selectedSchoolFullname');
        print('Selected School Nickname: $_selectedSchoolNickname');
        print('id: $_selectedSchoolIndex');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var selectedCoursesData = Provider.of<CoursesProvider>(context);
    return FutureBuilder<void>(
      future: _loadUserFuture, // This should be your future that fetches data
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        // Check the state of the future
        if (snapshot.connectionState == ConnectionState.waiting) {
          // If the Future is still running, show a loading indicator
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // If we run into an error, display it to the user
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          var selectedCoursesData = Provider.of<CoursesProvider>(context);
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
                        borderRadius: BorderRadius.all(
                            Radius.circular(30)), // 모서리를 둥글게 만듭니다.
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
                                  topRight:
                                      Radius.circular(20), // 상단 오른쪽 모서리 둥글게
                                ),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  heightFactor:
                                      0.8, // 이미지의 상위 80%만 보여줍니다. 하단 20%는 잘립니다.
                                  child: SvgPicture.asset(
                                    'assets/icons/univ.svg',
                                    width: MediaQuery.of(context).size.width,
                                    // height 설정을 제거하여 전체 이미지 높이를 기준으로 잘립니다.
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    right: 10, bottom: 80),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (widget.onboard == false)
                                      Container(
                                        height: 30,
                                        width: 30,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          shape: BoxShape
                                              .circle, // Ensures the container is circular
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            FeatherIcons.x,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline,
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
                            "Select Your University",
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
                              "Your university choice determines\ncourse availability. Select accurately for relevant course options.",
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  PullDownButton(
                                    itemBuilder: (BuildContext context) {
                                      return schoolsList
                                          .map((institution) =>
                                              PullDownMenuItem(
                                                title: institution
                                                    .nickname, // Use fullName for display
                                                subtitle: institution.fullName,
                                                onTap: () {
                                                  _onSchoolChanged(
                                                      institution.fullName);
                                                  setState(() {
                                                    _selectedSchoolFullname =
                                                        institution
                                                            .fullName; // Use nickname for selection
                                                  });
                                                },
                                              ))
                                          .toList();
                                    },
                                    buttonBuilder: (BuildContext context,
                                        Future<void> Function() showMenu) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .inversePrimary,
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: TextButton(
                                          onPressed: showMenu,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 50, vertical: 5),
                                            child: Text(
                                              _selectedSchoolFullname ??
                                                  "Select School",
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        widget.goBack();
                                        _saveAndClose();
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20),
                                        height: 55,
                                        width:
                                            MediaQuery.of(context).size.width /
                                                3,
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.redAccent,
                                                width: 2),
                                            color: Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(60)),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20),
                                        height: 55,
                                        width:
                                            MediaQuery.of(context).size.width /
                                                3,
                                        decoration: BoxDecoration(
                                            color: Colors.blueAccent,
                                            borderRadius:
                                                BorderRadius.circular(60)),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 30),
                                    height: 55,
                                    width:
                                        MediaQuery.of(context).size.width - 80,
                                    decoration: BoxDecoration(
                                        color: Colors.blueAccent,
                                        borderRadius:
                                            BorderRadius.circular(60)),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
      },
    );
  }
}
