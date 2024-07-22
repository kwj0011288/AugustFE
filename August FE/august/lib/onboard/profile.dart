import 'dart:convert';
import 'package:august/components/profile/contact_option.dart';
import 'package:august/components/profile/profile.dart';
import 'package:august/const/font/font.dart';
import 'package:august/provider/user_info_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:august/provider/courseprovider.dart';
import 'package:august/login/login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'package:contacts_service/contacts_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:image_cropper/image_cropper.dart';

class NamePage extends StatefulWidget {
  final bool onboard;
  final VoidCallback onTap;
  NamePage({
    Key? key,
    required this.onboard,
    required this.onTap,
  }) : super(key: key);

  @override
  _NamePageState createState() => _NamePageState();
}

class _NamePageState extends State<NamePage> {
  TextEditingController _nameController = TextEditingController();
  late Future<void> _loadUserFuture;
  String? imagePath; // Holds either a URL or a local path

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUserFuture = loadInfo();
  }

  void updateProfileImage(String imagePath) {
    Provider.of<UserInfoProvider>(context, listen: false)
        .updateUserProfileImage(imagePath);
    _saveInfo();
  }

  void updateName(String name) {
    Provider.of<UserInfoProvider>(context, listen: false).updateUserName(name);
  }

  Future<void> getImage() async {
    final pickedFile = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 20);
    if (pickedFile != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Cropper',
          ),
        ],
      );
      if (croppedFile != null) {
        setState(() {
          imagePath = croppedFile.path;
        });
        updateProfileImage(imagePath!); // Update shared state
      }
    }
  }

/*
Future<void> _pickContact() async {
    try {
      Contact? contact = await ContactsService.openDeviceContactPicker();
      if (contact != null) {
        // Concatenate givenName and familyName to get the full name
        String fullName = '';
        if (contact.givenName != null) {
          fullName += contact.givenName!;
        }
        if (contact.familyName != null) {
          // Add a space before the family name if the given name is not null
          if (fullName.isNotEmpty) {
            fullName += ' ';
          }
          fullName += contact.familyName!;
        }

        setState(() {
          setState(() {
            contactPhoto = contact.avatar;
            widget.onPhotoUpdated(contactPhoto); // Add this
          });

          _nameController.text = fullName; // Set the contact's full name
        });

        // Debugging: Check if the photo was fetched
        if (contactPhoto != null) {
          print("Contact photo fetched successfully.");
        } else {
          print("No photo available for this contact.");
        }
      }
    } catch (e) {
      // Handle any errors here and print them for debugging
      print("Error picking contact: $e");
    }
  }
*/
  Future<void> pickFromContact() async {
    try {
      Contact? contact = await ContactsService.openDeviceContactPicker();

      if (contact != null) {
        // Concatenate givenName and familyName to get the full name
        String fullName = '';
        if (contact.givenName != null) {
          fullName += contact.givenName!;
        }
        if (contact.familyName != null) {
          // Add a space before the family name if the given name is not null
          if (fullName.isNotEmpty) {
            fullName += ' ';
          }
          fullName += contact.familyName!;
        }
        Provider.of<UserInfoProvider>(context, listen: false)
            .updateUserName(fullName);
      }

      if (contact != null &&
          contact.avatar != null &&
          contact.avatar!.isNotEmpty) {
        final directory = await getApplicationDocumentsDirectory();
        File imgFile = File('${directory.path}/contact_image.png');
        imgFile.writeAsBytesSync(contact.avatar!);
        setState(() {
          imagePath = imgFile.path;
        });
        updateProfileImage(imagePath!);
      }
    } catch (e) {
      print("Failed to pick contact: $e");
    }
  }

  Future<void> useDefaultImage() async {
    setState(() {
      imagePath = 'assets/icons/memoji.png';
    });
    updateProfileImage(imagePath!); // Update shared state
  }

  Future<void> loadInfo() async {
    var infoProvider =
        Provider.of<UserInfoProvider>(context, listen: false).userInfo;
    _nameController.text = infoProvider!.name;
    imagePath = infoProvider.profileImage;

    // setState(() {
    //   _nameController.text = infoProvider!.name;
    //   imagePath = infoProvider.profileImage;
    // });
  }

  Future<void> _saveInfo() async {
    var infoProvider =
        Provider.of<UserInfoProvider>(context, listen: false).userInfo;
    infoProvider!.name = _nameController.text;
    infoProvider.profileImage = imagePath;
  }

  Widget buildImage() {
    if (imagePath == null) {
      return Image.asset('assets/icons/memoji.png'); // Default placeholder
    } else if (imagePath!.startsWith('http')) {
      return Image.network(imagePath!);
    } else {
      return Image.asset(imagePath!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadUserFuture, // This should be your future that fetches data
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        // Check the state of the future
        if (snapshot.connectionState == ConnectionState.waiting) {
          // If the Future is still running, show a loading indicator
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // If we run into an error, display it to the user
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return Scaffold(
            body: ColorfulSafeArea(
              child: SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                reverse: true,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Spacer(),
                          if (widget.onboard == false) SizedBox(height: 50),
                        ],
                      ),
                      if (widget.onboard == true) SizedBox(height: 50),
                      Text(
                        widget.onboard ? "Who Are You?" : "Change Your Profile",
                        style: AugustFont.head3(
                            color: Theme.of(context).colorScheme.outline),
                      ),
                      SizedBox(height: 30),
                      Text(
                        widget.onboard
                            ? "Set name and profile\nthat will be shown to others."
                            : "Change name and profile\nthat will be shown to others.",
                        textAlign: TextAlign.center,
                        style: AugustFont.head4(color: Colors.grey),
                      ),
                      SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ProfileWidget(
                              isBottomBar: false,
                              isProfilePage: true,
                            ),
                            Positioned(
                              right: 10,
                              bottom: 0,
                              child: ContactButton(
                                getMemoji: () {
                                  pickFromContact();
                                  HapticFeedback.mediumImpact();
                                },
                                openPhoto: () {
                                  getImage();
                                  HapticFeedback.mediumImpact();
                                },
                                defaultImage: () {
                                  useDefaultImage();
                                  HapticFeedback.mediumImpact();
                                },
                              ),
                              // child: CustomPopup(
                              //   showArrow: false,
                              //   contentPadding: EdgeInsets.symmetric(
                              //       horizontal: 30, vertical: 10),
                              //   arrowColor: Theme.of(context)
                              //       .colorScheme
                              //       .primaryContainer,
                              //   backgroundColor: Theme.of(context)
                              //       .colorScheme
                              //       .primaryContainer,
                              //   content: Column(
                              //     mainAxisSize: MainAxisSize.min,
                              //     crossAxisAlignment: CrossAxisAlignment.start,
                              //     children: <Widget>[
                              //       GestureDetector(
                              //         onTap: _pickContact,
                              //         child: Text(
                              //           'Get Memoji from Contacts',
                              //           style: TextStyle(
                              //             fontWeight: FontWeight.bold,
                              //             color: Theme.of(context)
                              //                 .colorScheme
                              //                 .outline,
                              //           ),
                              //         ),
                              //       ),
                              //       SizedBox(height: 5),
                              //       GestureDetector(
                              //         child: Text(
                              //           'Open Photo App',
                              //           style: TextStyle(
                              //             fontWeight: FontWeight.bold,
                              //             color: Theme.of(context)
                              //                 .colorScheme
                              //                 .outline,
                              //           ),
                              //         ),
                              //         onTap: getImage,
                              //       ),
                              //       SizedBox(height: 5),
                              //       GestureDetector(
                              //         child: Text(
                              //           'Use Default Image',
                              //           style: TextStyle(
                              //             fontWeight: FontWeight.bold,
                              //             color: Theme.of(context)
                              //                 .colorScheme
                              //                 .outline,
                              //           ),
                              //         ),
                              //         onTap: () async {
                              //           ByteData data = await rootBundle
                              //               .load('assets/icons/memoji.png');
                              //           Uint8List bytes =
                              //               data.buffer.asUint8List();
                              //           setState(() {
                              //             contactPhoto = bytes;
                              //           });
                              //           _saveInfo();
                              //         },
                              //       ),
                              //     ],
                              //   ),
                              //   child: Container(
                              //     height: 50,
                              //     width: 50,
                              //     decoration: BoxDecoration(
                              //       color: Theme.of(context)
                              //           .colorScheme
                              //           .background,
                              //       shape: BoxShape.circle,
                              //       border: Border.all(
                              //         color:
                              //             Theme.of(context).colorScheme.outline,
                              //         width: 2.0,
                              //       ),
                              //     ),
                              //     child: Icon(
                              //       Icons.add,
                              //       color:
                              //           Theme.of(context).colorScheme.outline,
                              //       size: 40,
                              //     ),
                              //   ),
                              // ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: CupertinoTextField(
                          textAlign: TextAlign.center,
                          controller: _nameController,
                          padding: EdgeInsets.all(10),
                          placeholder: "Enter Your Name",
                          placeholderStyle: AugustFont.profileName(
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                          style: AugustFont.profileName(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          cursorColor: Theme.of(context).colorScheme.outline,
                          cursorHeight: 40,
                          onChanged: (text) {
                            setState(() {}); // 텍스트 필드의 내용이 변경될 때마다 UI 업데이트
                          },
                          maxLength: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.only(
                left: 15,
                right: 15,
                bottom: 60,
              ),
              child: widget.onboard
                  ? GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        Future.delayed(Duration(milliseconds: 200), () {
                          widget.onTap();
                          // _saveAndClose();
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        height: 60,
                        width: MediaQuery.of(context).size.width - 80,
                        decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'NEXT',
                              style: AugustFont.head2(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: () {
                        //_saveAndClose();
                        HapticFeedback.mediumImpact();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        height: 55,
                        width: MediaQuery.of(context).size.width - 80,
                        decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(60)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'DONE',
                              style: AugustFont.head2(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          );
        }
      },
    );
  }
}

class ProfilePhotoNotifier extends ChangeNotifier {
  Uint8List? _photo;

  Uint8List? get photo => _photo;

  void updatePhoto(Uint8List? newPhoto) {
    _photo = newPhoto;
    notifyListeners();
  }
}
