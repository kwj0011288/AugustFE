import 'package:august/components/bottom_bar_friend.dart';
import 'package:august/components/my_bottombar.dart';
import 'package:august/pages/friend_request_page.dart';
import 'package:august/pages/friend_sent_page.dart';
import 'package:august/pages/friends_page.dart';
import 'package:august/pages/main/homepage.dart';
import 'package:august/pages/schedule_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import your FriendsRequestsPage and SentRequestsPage here

class FriendsAddPage extends StatefulWidget {
  @override
  _FriendsAddPageState createState() => _FriendsAddPageState();
}

class _FriendsAddPageState extends State<FriendsAddPage>
    with SingleTickerProviderStateMixin {
  List<Widget> _pages = [];
  int _currentIndex = 0;
  @override
  void initState() {
    super.initState();
    _pages = [FriendsRequestPage(), FriendsSentPage()];
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 80,
        toolbarHeight: 60,
        elevation: 0,
        title: Text(
          _currentIndex == 1 ? 'Sent Requests' : 'Friend Requests',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.background,
        leading: Padding(
          padding: const EdgeInsets.only(left: 0, top: 8, bottom: 8),
          child: GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary,
              ),
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
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: FriendsBottomBar(
          onIndexChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
