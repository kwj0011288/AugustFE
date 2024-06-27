import 'dart:convert';
import 'dart:typed_data';
import 'package:august/components/friends/number_box.dart';
import 'package:august/get_api/friends/invitation_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toasty_box/toasty_box.dart';

class InvitationCodePage extends StatefulWidget {
  const InvitationCodePage({Key? key}) : super(key: key);

  @override
  _InvitationCodePageState createState() => _InvitationCodePageState();
}

class _InvitationCodePageState extends State<InvitationCodePage> {
  String? formattedTime;
  Uint8List? profilePhoto;
  String? _code = "00000000";
  String? _expires;
  String? _url;

  @override
  void initState() {
    formatExpires();
    super.initState();
    initCode();

    loadProfilePhoto();
  }

  Future<void> initCode() async {
    final prefs = await SharedPreferences.getInstance();
    _expires = prefs.getString('codeExpires');
    if (isCodeExpired()) {
      await generateCode();
    } else {
      _code = prefs.getString('invitationCode') ?? _code;
      formattedTime = formatExpires();
    }
    setState(() {}); // Update UI after verification or generation
  }

  bool isCodeExpired() {
    if (_expires != null) {
      final now = DateTime.now();
      final expires = DateTime.parse(_expires!);
      print('Now: $now, Expires: $expires'); // Debug output to check values
      return expires.isBefore(now);
    }
    return true; // Assume expired if no expiry date is set
  }

  String formatExpires() {
    if (_expires != null) {
      final now = DateTime.now();
      final expires = DateTime.parse(_expires!);
      final duration = expires.difference(now);

      if (duration.isNegative) {
        return "Expired";
      } else {
        final days = duration.inDays;
        final hours = duration.inHours % 24;
        final minutes = duration.inMinutes % 60;

        return "${days}d ${hours}h ${minutes}m";
      }
    }
    return "No expiry date";
  }

  Future<void> generateCode() async {
    FriendsRequestCode requestCode =
        await FriendRequestService().createFriendRequestCode();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('codeExpires', requestCode.expires);
    await prefs.setString('invitationCode', requestCode.code);

    setState(() {
      _code = requestCode.code;
      _expires = requestCode.expires;
      formattedTime = formatExpires();
    });
  }

  Future<void> loadProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final base64Image = prefs.getString('contactPhoto');
    if (base64Image != null) {
      setState(() {
        profilePhoto = base64Decode(base64Image);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print(_expires);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.9),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 25),
              height: 310,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    maxRadius: 50,
                    backgroundImage: profilePhoto != null
                        ? MemoryImage(profilePhoto!)
                        : null,
                    child: profilePhoto == null
                        ? Image.asset('assets/icons/memoji.png')
                        : null,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Shareable Code",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      DigitBoxes(code: "$_code"),
                      Padding(
                        padding: const EdgeInsets.only(right: 10, bottom: 5),
                        child: Text(
                          formattedTime?.isEmpty ?? true
                              ? "Expires in 0 days 0 hours 0 minutes"
                              : "Expires in $formattedTime",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: "$_code"));
                      ToastService.showToast(
                        context,
                        isClosable: true,
                        backgroundColor:
                            Theme.of(context).colorScheme.background,
                        shadowColor: Theme.of(context).colorScheme.shadow,
                        leading: Icon(
                          FeatherIcons.checkCircle,
                          color: Colors.greenAccent,
                        ),
                        message: "Your invitation code has been copied!",
                      );
                    },
                    child: Text(
                      "Click here to copy code",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.pop(context, _code),
              child: CircleAvatar(
                radius: 25, // Increased radius for a larger avatar
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  FeatherIcons.x,
                  size: 25, // Increased size for the icon
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
