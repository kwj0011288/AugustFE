import 'package:august/components/home/button.dart';
import 'package:august/components/home/loading.dart';
import 'package:august/components/provider/courseprovider.dart';
import 'package:august/components/tile/onboardTile/univ_tile.dart';
import 'package:august/get_api/onboard/get_semester.dart';
import 'package:august/get_api/onboard/get_univ.dart';
import 'package:august/login/login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pull_down_button/pull_down_button.dart';
import "package:flutter_feather_icons/flutter_feather_icons.dart";
import 'package:colorful_safe_area/colorful_safe_area.dart';

class UnivPage extends StatefulWidget {
  final bool onboard;
  final List<Institution> institutions;
  final VoidCallback goBack;
  final VoidCallback gonext;
  UnivPage({
    Key? key,
    required this.onboard,
    required this.goBack,
    required this.gonext,
    required this.institutions,
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
    schoolsList = widget.institutions;
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
                  widget.onboard
                      ? "Select Your University"
                      : "Change Your University",
                  style: TextStyle(
                    fontSize: 35,
                    color: Theme.of(context).colorScheme.outline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    "Your university choice determines\ncourse availability.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 40),
                Container(
                  child: Form(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: schoolsList.map((institution) {
                        return UniversityTile(
                          fullname: institution.fullName,
                          nickname: institution.nickname,
                          tileColor: _selectedSchoolFullname ==
                                  institution.fullName
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.primaryContainer,
                          isShadow:
                              _selectedSchoolFullname == institution.fullName,
                          onTap: () {
                            _onSchoolChanged(institution.fullName);
                            setState(() {
                              _selectedSchoolFullname = institution.fullName;
                              _selectedSchoolNickname = institution.nickname;
                              _selectedSchoolIndex = institution.id;
                            });
                          },
                        );
                      }).toList(),
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
