import 'dart:convert';
import 'dart:typed_data';
import 'package:august/components/number_box.dart';
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
  Uint8List? profilePhoto;
  @override
  void initState() {
    super.initState();
    loadProfilePhoto();
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.9),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
              height: MediaQuery.of(context).size.height * 0.35,
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
                    "Invitation Code",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  DigitBoxes(
                      code:
                          "123123"), // Assuming this is a widget you've created
                  Spacer(),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: "123123"));
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
              onTap: () => Navigator.pop(context),
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
