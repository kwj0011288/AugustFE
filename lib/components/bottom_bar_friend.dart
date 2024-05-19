import 'package:august/pages/friends_page.dart';
import 'package:august/pages/me_page.dart';
import 'package:august/pages/schedule_page.dart';
import 'package:custom_navigation_bar/custom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import "package:flutter_feather_icons/flutter_feather_icons.dart";

class FriendsBottomBar extends StatefulWidget {
  final ValueChanged<int> onIndexChanged;

  FriendsBottomBar({
    Key? key,
    required this.onIndexChanged,
  }) : super(key: key);

  @override
  _FriendsBottomBarState createState() => _FriendsBottomBarState();
}

class _FriendsBottomBarState extends State<FriendsBottomBar> {
  int currentIndex = 0;

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
              icon: FeatherIcons.userPlus,
              text: 'Requests',
            ),
            GButton(
              icon: FeatherIcons.send,
              text: 'Sent',
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
