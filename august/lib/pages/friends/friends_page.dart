import 'dart:convert';
import 'package:august/components/add_friend.dart';
import 'package:august/components/invitation_code.dart';
import 'package:august/get_api/Friendsdummy.dart';
import 'package:august/get_api/get_semester.dart';
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

class FriendsPage extends StatefulWidget {
  final String semester;

  const FriendsPage({Key? key, required this.semester}) : super(key: key);

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  int bottomIndex = 0;
  String? selectedValue;
  Uint8List? profilePhoto;
  TextEditingController inviteController = TextEditingController();

  String formatSemester(String semester) {
    String year = semester.substring(0, 4);
    String season = getSeasonFromSemester(semester);
    return "$season $year";
  }

  @override
  void initState() {
    super.initState();
    if (widget.semester.isNotEmpty) {
      selectedValue = widget.semester;
    }

    _loadProfilePhoto();
    _listenForPhotoChanges(); // Listen for photo changes if using a Provider
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
                      LengthLimitingTextInputFormatter(3),
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
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                  ),
                ),
                SizedBox(
                    width:
                        10), // Provide some spacing between the text field and the button
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: ColorfulSafeArea(
          bottomColor: Colors.white.withOpacity(0),
          overflowRules: OverflowRules.only(bottom: true),
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
                          dataList.length.toString() + ' Friends',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        Text(
                          'Are you insider?',
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
                      onTap: () {
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
              dataList.length != 0
                  ? Expanded(
                      child: GridView.builder(
                        itemCount:
                            dataList.length + 1, // itemCount를 dataList의 길이로 설정
                        padding: EdgeInsets.only(
                            top: 20, left: 20, right: 20, bottom: 100),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // 한 줄에 표시할 항목의 수
                          crossAxisSpacing: 20.0, // 가로 간격
                          mainAxisSpacing: 20.0, // 세로 간격
                          childAspectRatio: (20 / 25), // 가로 세로 비율 조정
                        ),
                        itemBuilder: (context, index) {
                          if (index == dataList.length) {
                            // If it is, return the red box
                            return GestureDetector(
                              onTap: () {
                                InvitationInput();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              showCupertinoModalBottomSheet(
                                context: context,
                                backgroundColor: Colors
                                    .transparent, // BottomSheet 배경을 투명하게 설정
                                topRadius: Radius.circular(30),
                                builder: (BuildContext context) {
                                  return Container(
                                    height: MediaQuery.of(context).size.height *
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
                                          'http://augustapp.one/media/profile_images/profile_image_nAVvCvz.png',
                                      name: dataList[index].title,
                                    ),
                                  );
                                },
                              );
                            },

                            child: Container(
                              padding: EdgeInsets.all(10), // 내부 여백 추가
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(30),
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
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 120, // 이미지의 가로 크기를 80으로 설정
                                    height: 120, // 이미지의 세로 크기를 80으로 설정
                                    child: ClipOval(
                                      child: Image.asset(
                                          dataList[index].imageName,
                                          fit: BoxFit.cover),
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(dataList[index].title,
                                      style: TextStyle(fontSize: 20)), // 이름 표시
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
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          SizedBox(height: 20),
                          AnimationFriends(),
                          SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: GestureDetector(
                              onTap: () {
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
                                      color:
                                          Theme.of(context).colorScheme.outline,
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
    );
  }
}
