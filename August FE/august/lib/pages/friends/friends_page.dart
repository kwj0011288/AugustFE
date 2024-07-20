import 'dart:convert';
import 'package:august/components/friends/add_friend.dart';
import 'package:august/components/friends/number_box.dart';
import 'package:august/const/font/font.dart';
import 'package:august/provider/friends_provider.dart';
import 'package:august/get_api/friends/delete_friend.dart';
import 'package:august/get_api/friends/friends_sem.dart';
import 'package:august/get_api/friends/verify_friend.dart';
import 'package:august/login/login.dart';
import 'package:august/pages/friends/my_code.dart';
import 'package:august/get_api/friends/get_friends.dart';
import 'package:august/get_api/onboard/get_semester.dart';
import 'package:august/onboard/profile.dart';
import 'package:august/pages/friends/friend_schedule_page.dart';
import 'package:august/provider/semester_provider.dart';
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
import 'package:toasty_box/toasty_box.dart';
import 'dart:math' as math;

class FriendsPage extends StatefulWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with TickerProviderStateMixin {
  int bottomIndex = 0;
  List<FriendInfo> friends = [];
  bool isLoading = true;
  bool isEdit = false;
  String? selectedValue;
  Uint8List? profilePhoto;
  TextEditingController inviteController = TextEditingController();
  AnimationController? _controller;
  AnimationController? _jiggleController;
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  AnimationController? _refreshFriendsController;
  String? _ownInvitationCode;

  @override
  void initState() {
    super.initState();
    loadFriends();

    _loadProfilePhoto();
    _listenForPhotoChanges(); // Listen for photo changes if using a Provider
    //refresh button
    _refreshFriendsController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    //for edit button
    _controller = AnimationController(
      duration: const Duration(
          milliseconds:
              300), // Adjust duration to control speed of the animation
      vsync: this,
    );

    //for trashcan jiggle
    _jiggleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  void toggleisEdit(int friendListLength) {
    setState(() {
      isEdit =
          friendListLength > 0 ? !isEdit : false; // Toggle the edit mode state
    });
    if (isEdit) {
      _controller!.forward(); // Animate to expanded aspect ratio
    } else {
      _controller!.reverse(); // Animate to normal aspect ratio
    }
  }

  Widget JiggleTrashIcon() {
    return AnimatedBuilder(
      animation: _jiggleController!,
      child: Icon(FeatherIcons.trash2, color: Colors.black, size: 40),
      builder: (context, child) {
        // Use sin function to create the jiggle effect
        final angle = math.sin(_jiggleController!.value * 5 * math.pi) *
            0.1; // Adjust amplitude for more/less jiggle
        return Transform.rotate(
          angle: angle,
          child: child,
        );
      },
    );
  }

  Future<void> loadFriends() async {
    try {
      var fetchedFriends = await FriendInfos().fetchFriends();
      if (mounted) {
        setState(() {
          friends = fetchedFriends;
          isLoading = false;
        });
        Provider.of<FriendsProvider>(context, listen: false)
            .setFriendsCount(friends.length);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
    _controller!.dispose();
    _jiggleController!.dispose();
    _refreshController.dispose();
    _refreshFriendsController!.dispose();
    super.dispose();
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

  void addFriend(String input) async {
    // Assuming VerifyFriendService is properly imported and initialized
    var response = await VerifyFriendService().acceptFriendRequest(input);

    if (_ownInvitationCode == input) {
      ToastService.showToast(
        context,
        backgroundColor: Theme.of(context).colorScheme.background,
        shadowColor: Theme.of(context).colorScheme.shadow,
        leading: Icon(
          FeatherIcons.xCircle,
          color: Colors.redAccent,
        ),
        message: "Yo! You can't add yourself as a friend.",
      );
    } else if (!response.success) {
      ToastService.showToast(
        context,
        backgroundColor: Theme.of(context).colorScheme.background,
        shadowColor: Theme.of(context).colorScheme.shadow,
        leading: Icon(
          FeatherIcons.xCircle,
          color: Colors.redAccent,
        ),
        message: "This code is invalid or expired. Please try again.",
      );
    } else {
      ToastService.showToast(
        context,
        backgroundColor: Theme.of(context).colorScheme.background,
        shadowColor: Theme.of(context).colorScheme.shadow,
        leading: Icon(
          FeatherIcons.checkCircle,
          color: Colors.greenAccent,
        ),
        message: "You have successfully added a friend!",
      );
    }
  }

  Widget weightModal(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      child: Container(
        color: Theme.of(context).colorScheme.background,
        padding: EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Text(
              "Invitation Code?",
              style: AugustFont.head1(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: CupertinoTextField(
                    inputFormatters: [
                      UpperCaseTextFormatter(),
                      LengthLimitingTextInputFormatter(8),
                    ],
                    autofocus: true,
                    controller: inviteController,
                    placeholder: 'Type Invitation Code',
                    placeholderStyle: AugustFont.textField2(
                        color: Theme.of(context).colorScheme.outline),
                    style: AugustFont.textField2(
                        color: Theme.of(context).colorScheme.outline),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    cursorColor: Theme.of(context).colorScheme.outline,
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                    onSubmitted: (value) {
                      // 이벤트 처리기 추가
                      Navigator.of(context).pop();
                      addFriend(inviteController.text);
                      inviteController.clear();

                      Future.delayed(Duration(microseconds: 1500), () {
                        loadFriends();
                      });
                    },
                  ),
                ),
                SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    addFriend(inviteController.text);
                    inviteController.clear();

                    Future.delayed(Duration(microseconds: 1500), () {
                      loadFriends();
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 18, horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      'Done',
                      style: AugustFont.head6(
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

  Future<void> deleteFriends(int friendId) async {
    // Show a confirmation dialog to confirm deletion
    final bool? deleted = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Text(
              textAlign: TextAlign.center,
              'Are you sure?',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            content: Text(
              textAlign: TextAlign.center,
              "He/She will be removed from friends list.",
              style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 15,
                  fontWeight: FontWeight.normal),
            ),
            actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop(true);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 30),
                      height: 55,
                      width: MediaQuery.of(context).size.width / 3.3,
                      decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(60)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Delete',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop(false);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 30),
                      height: 55,
                      width: MediaQuery.of(context).size.width / 3.3,
                      decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(60)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Keep',
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
              ),
            ],
          ),
        );
      },
    );

    if (deleted!) {
      // Delete the friend from your database or API here
      await deleteFriend(friendId);
      // Fetch the updated list of friends
      friends = await FriendInfos().fetchFriends();

      // Rebuild the widget with the updated list of friends
      setState(() {});
    }
  }

  void _onRefresh() async {
    try {
      HapticFeedback.mediumImpact();
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
          child: SmartRefresher(
            enablePullDown: true,
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
                            style: AugustFont.head1(
                                color: Theme.of(context).colorScheme.outline),
                          ),
                          Text(
                            'Are you an extrovert?',
                            style: AugustFont.subText(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(left: 15, right: 15),
                      child: GestureDetector(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          var result = await Navigator.push(
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
                              transitionDuration: Duration(milliseconds: 200),
                            ),
                          );

                          if (result != null) {
                            _ownInvitationCode = result;
                            print("Received invitation code: $result");
                            // You can use the `result` here to perform further operations
                          }

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
                              style: AugustFont.head4(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (friends.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10, right: 10),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                toggleisEdit(friends.length);
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  height: 30,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: isEdit
                                        ? Colors.blueAccent
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                  child: Center(
                                    child: Text(
                                      isEdit ? 'Done' : 'Edit',
                                      style: AugustFont.subText(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 10, top: 10),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () async {
                                final SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                loadFriends();
                                await prefs.remove('codeExpires');
                                await prefs.remove('invitationCode');
                                _refreshFriendsController!.forward(from: 0.0);
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(top: 5, right: 15),
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  child: Center(
                                    child: RotationTransition(
                                      turns: Tween(begin: 0.0, end: 1.0)
                                          .animate(_refreshFriendsController!),
                                      child: Icon(
                                        Icons.refresh,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline,
                                        size: 23,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                isLoading
                    ? Container()
                    : friends.isNotEmpty
                        ? Expanded(
                            child: GridView.extent(
                              maxCrossAxisExtent:
                                  200, // Max width of each item, adjust as needed
                              padding:
                                  EdgeInsets.only(top: 10, left: 20, right: 20),
                              crossAxisSpacing: 20.0,
                              mainAxisSpacing: 20.0,
                              childAspectRatio: (10 / 11),
                              //  itemCount: friends.length + 2,
                              children: List.generate(
                                friends.length + 2,
                                (index) {
                                  if (index == friends.length) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        borderRadius: BorderRadius.circular(10),
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
                                      onTap: () {
                                        InvitationInput();
                                        checkAccessToken();
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
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              FeatherIcons.plus,
                                              size: 40,
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              'Add Friends',
                                              style: AugustFont.head4(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .outline,
                                              ),
                                            ),
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
                                      if (!isEdit) {
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
                                                  topRight:
                                                      Radius.circular(100),
                                                ),
                                              ),
                                              child: FriendSchedulePage(
                                                photoUrl:
                                                    friends[index].profileImage,
                                                name: friends[index].name,
                                                department:
                                                    friends[index].department,
                                                yearInSchool: convertDepartment(
                                                    friends[index]
                                                        .yearInSchool),
                                                friendId: friends[index].id,
                                              ),
                                            );
                                          },
                                        );
                                        refreshToken().then((_) {
                                          checkAccessToken();
                                        });
                                      } else {
                                        deleteFriends(friends[index].id);
                                      }
                                    },
                                    child: AnimatedContainer(
                                      duration: Duration(milliseconds: 200),
                                      padding: EdgeInsets.all(0), // 내부 여백 추가
                                      decoration: BoxDecoration(
                                        color: isEdit
                                            ? Colors.redAccent
                                            : Theme.of(context)
                                                .colorScheme
                                                .primaryContainer,
                                        borderRadius: BorderRadius.circular(10),
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
                                      child: (!isEdit)
                                          ? Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  CircleAvatar(
                                                    maxRadius: 50,
                                                    backgroundImage: friends[
                                                                    index]
                                                                .profileImage !=
                                                            null
                                                        ? NetworkImage(
                                                            friends[index]
                                                                .profileImage!)
                                                        : null,
                                                    child: friends[index]
                                                                .profileImage ==
                                                            null
                                                        ? Icon(Icons.person,
                                                            size: 45)
                                                        : null,
                                                  ),
                                                  SizedBox(height: 5),
                                                  Text(
                                                    friends[index].name,
                                                    style: AugustFont.head6(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .outline,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        friends[index]
                                                            .department,
                                                        style: AugustFont
                                                            .captionBold(
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      SizedBox(width: 5),
                                                      Text(
                                                        '|',
                                                        style: AugustFont
                                                            .captionSmall(
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      SizedBox(width: 5),
                                                      Text(
                                                        friends[index]
                                                            .yearInSchool,
                                                        style: AugustFont
                                                            .captionBold(
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      SizedBox(width: 5),
                                                      Text(
                                                        '|',
                                                        style: AugustFont
                                                            .captionSmall(
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      SizedBox(width: 5),
                                                      Text(
                                                        friends[index]
                                                            .yearInSchool,
                                                        style: AugustFont
                                                            .captionBold(
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            )
                                          : Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Align(
                                                    alignment: Alignment.center,
                                                    child: CircleAvatar(
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        maxRadius: 50,
                                                        child:
                                                            JiggleTrashIcon()),
                                                  ),
                                                  Text(
                                                    friends[index].name,
                                                    style: AugustFont.head6(
                                                      color: Colors.black,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),
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
                                  style: AugustFont.head2(
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
                                      InvitationInput();
                                      await checkAccessToken();
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
                                          style: AugustFont.head4(
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

// UpperCaseTextFormatter definition
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
