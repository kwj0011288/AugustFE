import 'dart:typed_data';
import 'dart:convert';
import 'package:august/onboard/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class ProfileWidget extends StatefulWidget {
  final List<String> departments;
  final bool isBottomBar;

  const ProfileWidget({
    Key? key,
    this.departments = const [],
    required this.isBottomBar,
  }) : super(key: key);

  @override
  _ProfileWidgetState createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  Uint8List? profilePhoto;

  @override
  void initState() {
    super.initState();
    _loadInfo();
    initProfilePhoto();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Load image
    String? base64Image = prefs.getString('contactPhoto');

    if (base64Image != null) {
      setState(() {
        profilePhoto = base64Decode(base64Image);
      });
    }
  }

  Future<Uint8List?> loadProfilePhoto({int retryCount = 0}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? base64Image = prefs.getString('contactPhoto');

    if (base64Image != null) {
      print('Profile photo loaded successfully.');
      return base64Decode(base64Image);
    } else if (retryCount < 2) {
      print('Profile photo not found, retrying...');
      await Future.delayed(Duration(seconds: 1));
      return loadProfilePhoto(retryCount: retryCount + 1);
    } else {
      print('Failed to load profile photo after several attempts.');
      return null; // Return null if all retries fail
    }
  }

  Future<void> initProfilePhoto() async {
    profilePhoto = await loadProfilePhoto();
    setState(() {});

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.isBottomBar ? EdgeInsets.all(5.0) : EdgeInsets.all(0.0),
      child: CircleAvatar(
        backgroundColor: Colors.grey,
        backgroundImage:
            profilePhoto != null ? MemoryImage(profilePhoto!) : null,
      ),
    );
  }
}
