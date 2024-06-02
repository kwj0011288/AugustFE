import 'dart:convert';
import 'package:august/components/add_friend.dart';
import 'package:august/get_api/friends/friends_sem.dart';
import 'package:august/get_api/friends/verify_friend.dart';
import 'package:august/login/login.dart';
import 'package:august/pages/friends/invitation_code.dart';
import 'package:august/get_api/friends/get_friends.dart';
import 'package:august/get_api/onboard/get_semester.dart';
import 'package:august/onboard/profile.dart';
import 'package:august/pages/friends/friend_schedule_page.dart';
import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import "package:flutter_feather_icons/flutter_feather_icons.dart";
import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class FriendsPage extends StatefulWidget {
  final String semester;

  const FriendsPage({Key? key, required this.semester}) : super(key: key);

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  int bottomIndex = 0;
  List<FriendInfo> friends = [];
  bool isLoading = true;
  String? selectedValue;
  Uint8List? profilePhoto;
  TextEditingController inviteController = TextEditingController();
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  String formatSemester(String semester) {
    String year = semester.substring(0, 4);
    String season = getSeasonFromSemester(semester);
    return "$season $year";
  }

  @override
  void initState() {
    super.initState();
    loadFriends();
    if (widget.semester.isNotEmpty) {
      selectedValue = widget.semester;
    }

    _loadProfilePhoto();
    _listenForPhotoChanges(); // Listen for photo changes if using a Provider
  }

  Future<void> loadFriends() async {
    try {
      friends = await FriendInfos().fetchFriends();
      ;
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Failed to load friends: $e');
    }
  }

  void _listenForPhotoChanges() {
    final photoNotifier =
        Provider.of<ProfilePhotoNotifier>(context, listen: false);
    photoNotifier.addListener(() {
      if (mounted) {
        setState(() {
          profilePhoto = photoNotifier.photo;
        });
      }
    });
  }

  Future<void> _loadProfilePhoto() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? base64Image = prefs.getString('contactPhoto');
    if (base64Image != null) {
      setState(() {
        profilePhoto = base64Decode(base64Image);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _refreshController.dispose();
  }

  String convertDepartment(String department) {
    switch (department) {
      case 'FR':
        department = 'Freshman';
        break;
      case 'SO':
        department = 'Sophomore';
        break;
      case 'JR':
        department = 'Junior';
        break;
      case 'SR':
        department = 'Senior';
        break;
      default:
        department = 'New?'; // 기본값 또는 오류 처리
    }
    return department;
  }

  Future<void> InvitationInput() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return weightModal(context);
      },
    );

    if (result != null) {
      print(result);
    }
  }

  Widget weightModal(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      child: Container(
        color: Theme.of(context).colorScheme.background,
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Text(
              "Invitation Code?",
              style: TextStyle(
                fontSize: 25,
                color: Theme.of(context).colorScheme.outline,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: CupertinoTextField(
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(8),
                    ],
                    autofocus: true,
                    controller: inviteController,
                    placeholder: 'Type Invitation Code',
                    placeholderStyle: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    cursorColor: Theme.of(context).colorScheme.outline,
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                  ),
                ),
                SizedBox(
                    width:
                        10), // Provide some spacing between the text field and the button
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    loadFriends();
                    VerifyFriendService()
                        .acceptFriendRequest(inviteController.text);
                    inviteController.clear();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 18, horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onRefresh() async {
    try {
      await loadFriends();
      _refreshController.refreshCompleted();
    } catch (error) {
      _refreshController.refreshFailed();
      print("Error during refresh: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: ColorfulSafeArea(
          bottomColor: Colors.white.withOpacity(0),
          overflowRules: OverflowRules.only(bottom: true),
          child: SmartRefresher(
            enablePullDown: true,
            enablePullUp: true,
            onRefresh: _onRefresh,
            controller: _refreshController,
            header: MaterialClassicHeader(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friends.length.toString() + ' Friends',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          Text(
                            'Are you extrovert?',
                            style: TextStyle(fontSize: 15, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 15, right: 15, top: 15),
                      child: GestureDetector(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              opaque: false,
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      InvitationCodePage(),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                              transitionDuration: Duration(
                                  milliseconds:
                                      200), // Customize the duration as needed
                            ),
                          );
                          await checkAccessToken();
                        },
                        child: Container(
                          width: 100,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          child: Center(
                            child: Text(
                              'My Code',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Align(
                //   alignment: Alignment.centerRight,
                //   child: GestureDetector(
                //     onTap: () {
                //       //toggleisEdit();
                //     },
                //     child: Padding(
                //       padding:
                //           const EdgeInsets.only(top: 10, bottom: 10, right: 20),
                //       child: AnimatedContainer(
                //         duration: Duration(milliseconds: 300),
                //         width: 60,
                //         height: 35,
                //         decoration: BoxDecoration(
                //           borderRadius: BorderRadius.circular(30),
                //           // color: isEdit
                //           //     ? Colors.blueAccent
                //           //     : Theme.of(context).colorScheme.primary,
                //           color: Colors.blueAccent,
                //         ),
                //         child: Center(
                //           child: Text(
                //             'Edit',
                //             // isEdit ? 'Done' : 'Edit',
                //             style: TextStyle(
                //               fontSize: 15,
                //               color: Theme.of(context).colorScheme.outline,
                //               fontWeight: FontWeight.bold,
                //             ),
                //           ),
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
                isLoading
                    ? Container()
                    : friends.isNotEmpty
                        ? Expanded(
                            child: GridView.builder(
                              itemCount: friends.length +
                                  2, // itemCount를 dataList의 길이로 설정
                              padding: EdgeInsets.only(
                                  top: 20, left: 20, right: 20, bottom: 100),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, // 한 줄에 표시할 항목의 수
                                crossAxisSpacing: 30.0, // 가로 간격
                                mainAxisSpacing: 30.0, // 세로 간격
                                childAspectRatio: (10 / 11), // 가로 세로 비율 조정
                              ),
                              itemBuilder: (context, index) {
                                if (index == friends.length) {
                                  // If it is, return the red box
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .shadow,
                                          blurRadius: 10,
                                          offset: Offset(6, 4),
                                        ),
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .shadow,
                                          blurRadius: 10,
                                          offset: Offset(-2, 0),
                                        ),
                                      ],
                                    ),
                                    child: Center(child: Text('Ad space')),
                                  );
                                } else if (index == friends.length + 1) {
                                  return GestureDetector(
                                    onTap: () async {
                                      InvitationInput();
                                      await checkAccessToken();
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .shadow,
                                            blurRadius: 10,
                                            offset: const Offset(6, 4),
                                          ),
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .shadow,
                                            blurRadius: 10,
                                            offset: const Offset(-2, 0),
                                          ),
                                        ],
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            FeatherIcons.plus,
                                            size: 40,
                                          ),
                                          Text('Add Friends')
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                // dataList에서 각 항목에 대한 정보를 사용하여 UI 구성
                                return GestureDetector(
                                  // onTap에서 호출되는 부분
                                  onTap: () async {
                                    await checkAccessToken();

                                    /* 여기 */
                                    var semesters = await FriendSemester()
                                        .fetchFriendSemester(friends[index].id);
                                    HapticFeedback.mediumImpact();
                                    showCupertinoModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors
                                          .transparent, // BottomSheet 배경을 투명하게 설정
                                      topRadius: Radius.circular(30),
                                      builder: (BuildContext context) {
                                        return Container(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.93, // BottomSheet의 높이 조정
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .background, // BottomSheet의 배경색
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(100),
                                              topRight: Radius.circular(100),
                                            ),
                                          ),
                                          child: FriendSchedulePage(
                                            photoUrl:
                                                friends[index].profileImage,
                                            name: friends[index].name,
                                            department:
                                                friends[index].department,
                                            yearInSchool: convertDepartment(
                                                friends[index].yearInSchool),
                                            semesterList: semesters,
                                            friendId: friends[index].id,
                                          ),
                                        );
                                      },
                                    );
                                  },

                                  child: Container(
                                    padding: EdgeInsets.all(0), // 내부 여백 추가
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .shadow,
                                          blurRadius: 10,
                                          offset: Offset(6, 4),
                                        ),
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .shadow,
                                          blurRadius: 10,
                                          offset: Offset(-2, 0),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 80, // 이미지의 가로 크기를 80으로 설정
                                          height: 80, // 이미지의 세로 크기를 80으로 설정
                                          child: ClipOval(
                                            child:
                                                friends[index].profileImage !=
                                                        null
                                                    ? Image.network(
                                                        friends[index]
                                                            .profileImage!,
                                                        fit: BoxFit.cover)
                                                    : Icon(Icons.person,
                                                        size: 70), // 기본 아이콘 표시
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Text(friends[index].name,
                                            style: TextStyle(
                                                fontSize: 15)), // 이름 표시
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : SizedBox(
                            height: MediaQuery.of(context).size.height * 0.7,
                            width: MediaQuery.of(context).size.width,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Wanna Invite Friends?',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                                SizedBox(height: 20),
                                AnimationFriends(),
                                SizedBox(height: 20),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: GestureDetector(
                                    onTap: () async {
                                      await checkAccessToken();
                                      InvitationInput();
                                    },
                                    child: Container(
                                      width: MediaQuery.of(context).size.width,
                                      padding: EdgeInsets.symmetric(
                                          vertical: 18, horizontal: 15),
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Click here to Add Friends',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
