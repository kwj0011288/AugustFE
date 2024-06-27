import 'package:flutter/material.dart';

class FriendsProvider extends ChangeNotifier {
  int _friendsCount = 0;

  int get friendsCount => _friendsCount;

  void setFriendsCount(int count) {
    _friendsCount = count;
    notifyListeners();
  }
}
