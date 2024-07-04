import 'package:august/components/tile/onboardTile/major_tile.dart';
import 'package:august/login/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:august/get_api/onboard/get_department.dart'; // Make sure this import is correct
import "package:flutter_feather_icons/flutter_feather_icons.dart";
import 'package:flutter_svg/svg.dart';
import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:animated_hint_textfield/animated_hint_textfield.dart';

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
  String? _selectedMajorFullname;
  String? _selectedMajorNickname;
  int? _selectedMajorIndex;
  List<String> filteredDepartments = [];

  TextEditingController searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    filteredDepartments = widget.preloadedDepartments;
    print("Preloaded Departments: ${widget.preloadedDepartments}");
    //  _selectedMajorIndex = 1;
    if (widget.preloadedDepartments.isEmpty) {
      // If the preloaded departments list is empty, fetch the departments
      fetchDepartments().then((departments) {
        setState(() {
          widget.preloadedDepartments = departments;
        });
      });
    }
  }

  void _filterDepartments(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredDepartments = widget.preloadedDepartments;
      });
    } else {
      setState(() {
        filteredDepartments = widget.preloadedDepartments.where((dept) {
          final parts = dept.split(', ');
          final fullnameAndNickname = parts.sublist(1).join(", ");

          final nickname = fullnameAndNickname.contains("(")
              ? fullnameAndNickname.split(" (")[1].replaceAll(")", "")
              : '';
          return nickname.toLowerCase().contains(query.toLowerCase());
        }).toList();
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
    return Scaffold(
      body: ColorfulSafeArea(
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    if (widget.onboard == true)
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 20, top: 8, bottom: 8),
                        child: GestureDetector(
                          onTap: () {
                            widget.goBack();
                            _saveAndClose();
                          },
                          child: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.background,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 5),
                              child: Center(
                                child: Icon(
                                  Icons.arrow_back_ios,
                                  size: 15,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Spacer(),
                    if (widget.onboard == false)
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 20, top: 5, bottom: 10),
                        child: GestureDetector(
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
                      ),
                  ],
                ),
                if (widget.onboard == true) SizedBox(height: 10),
                Text(
                  widget.onboard ? "Select Major" : "Change Major",
                  style: TextStyle(
                    fontSize: 35,
                    color: Theme.of(context).colorScheme.outline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    "Selected Semester is used for\nCourse search, and Schedule Creation.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                      top: 15.0, bottom: 15.0, left: 10.0, right: 10.0),
                  child: AnimatedTextField(
                      animationType: Animationtype.typer,
                      cursorColor: Theme.of(context).colorScheme.outline,
                      controller: searchController,
                      hintTexts: const [
                        'CMSC',
                        'BMGT',
                        'INST',
                        'HIST',
                        'BIOL',
                        'MATH',
                      ],
                      animationDuration: Duration(milliseconds: 500),
                      hintTextStyle: const TextStyle(
                        color: Colors.grey,
                        overflow: TextOverflow.ellipsis,
                      ),
                      decoration: InputDecoration(
                        fillColor: Theme.of(context).colorScheme.primary,
                        filled: true, // 배경색 채우기 활성화
                        contentPadding: EdgeInsets.symmetric(vertical: 15.0),
                        border: OutlineInputBorder(
                          // 기본 테두리 설정
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none, // 둘레 색 없애기
                        ),
                        focusedBorder: OutlineInputBorder(
                          // 포커스 됐을 때의 테두리 설정
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none, // 둘레 색 없애기
                        ),
                        prefixIcon: Icon(
                          FeatherIcons.search,
                          size: 25.0,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      onChanged: _filterDepartments,
                      onSubmitted: (value) {
                        // This is called when the done button is pressed.
                        FocusScope.of(context).unfocus();
                      },
                      textInputAction: TextInputAction.done),
                ),
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView.builder(
                      itemCount: filteredDepartments.length,
                      itemBuilder: (BuildContext context, int index) {
                        final parts = filteredDepartments[index].split(', ');
                        final fullnameAndNickname = parts.sublist(1).join(", ");
                        final fullname = fullnameAndNickname.split(" (")[0];
                        final nickname = fullnameAndNickname.contains("(")
                            ? fullnameAndNickname
                                .split(" (")[1]
                                .replaceAll(")", "")
                            : '';
                        return MajorTile(
                          fullname: fullname,
                          nickname: nickname,
                          tileColor: _selectedMajorNickname == nickname
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.primaryContainer,
                          isShadow: _selectedMajorNickname == nickname,
                          onTap: () {
                            setState(() {
                              _selectMajor(filteredDepartments[index]);
                              _selectedMajorNickname = nickname;
                              _selectedMajorFullname = fullname;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(
          left: 15,
          right: 15,
          bottom: 60,
          top: 20,
        ),
        child: widget.onboard
            ? GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.gonext();
                  _saveAndClose();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  height: 60,
                  width: MediaQuery.of(context).size.width - 80,
                  decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
      ),
    );
  }
}
