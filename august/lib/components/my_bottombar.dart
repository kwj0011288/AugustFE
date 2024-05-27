import 'package:august/pages/friends/friends_page.dart';
import 'package:august/pages/profile/me_page.dart';
import 'package:august/pages/main/schedule_page.dart';
import 'package:custom_navigation_bar/custom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import "package:flutter_feather_icons/flutter_feather_icons.dart";

class BottomBar extends StatefulWidget {
  final ValueChanged<int> onIndexChanged;

  BottomBar({
    Key? key,
    required this.onIndexChanged,
  }) : super(key: key);

  @override
  _BottomBarState createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  int currentIndex = 0;

  // @override
  // Widget build(BuildContext context) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 20),
  //     child: CustomNavigationBar(
  //       iconSize: 30.0,
  //       selectedColor: Color(0xff040307),
  //       strokeColor: Color(0x30040307),
  //       unSelectedColor: Color(0xffacacac),
  //       backgroundColor: Theme.of(context).colorScheme.primary,
  //       isFloating: true,
  //       borderRadius: Radius.circular(30.0),
  //       items: [
  //         CustomNavigationBarItem(
  //           icon: Image.asset(
  //             'assets/icons/home.png',
  //             color: Theme.of(context).colorScheme.outline,
  //           ),
  //         ),
  //         CustomNavigationBarItem(
  //           icon: Image.asset(
  //             'assets/icons/friends.png',
  //             height: 30,
  //             width: 30,
  //             color: Theme.of(context).colorScheme.outline,
  //           ),
  //         ),
  //       ],
  //       currentIndex: currentIndex,
  //       onTap: (index) {
  //         setState(() {
  //           currentIndex = index;
  //         });
  //         widget.onIndexChanged(index);
  //       },
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.only(
          left: deviceWidth / 6, right: deviceWidth / 6, bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .primaryContainer, // Container background color
          borderRadius:
              BorderRadius.all(Radius.circular(100)), // Adjust the radius here
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
        child: GNav(
          tabMargin: EdgeInsets.all(8),
          backgroundColor: Colors.transparent,
          color: Colors.grey,
          activeColor: Theme.of(context).colorScheme.outline,
          tabBackgroundColor: Theme.of(context).colorScheme.primary,
          gap: 10,
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          haptic: true,
          tabs: const [
            GButton(
              icon: FeatherIcons.layout,
              text: 'Schedules',
            ),
            GButton(
              icon: Icons.people,
              text: 'Friends',
            ),
          ],
          selectedIndex: currentIndex,
          onTabChange: (index) {
            setState(() {
              currentIndex = index;
            });
            widget.onIndexChanged(index);
          },
        ),
      ),
    );
  }
}
