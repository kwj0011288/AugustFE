import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:august/components/button.dart';
import 'package:august/components/courseprovider.dart';
import 'package:august/login/login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart'
    as contact_picker;
import 'dart:typed_data';
import 'package:contacts_service/contacts_service.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import "package:flutter_feather_icons/flutter_feather_icons.dart";
import 'package:image_cropper/image_cropper.dart';

class NamePage extends StatefulWidget {
  final bool onboard;
  final VoidCallback onTap;
  final Function(Uint8List?) onPhotoUpdated;
  NamePage({
    Key? key,
    required this.onboard,
    required this.onTap,
    required this.onPhotoUpdated,
  }) : super(key: key);

  @override
  _NamePageState createState() => _NamePageState();
}

class _NamePageState extends State<NamePage> {
  TextEditingController _nameController = TextEditingController();
  late Future<void> _loadUserFuture;

  @override
  void dispose() {
    _nameController.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _loadUserFuture = _loadInfo();
  }

  final ImagePicker _picker = ImagePicker();
  Uint8List? contactPhoto; // Variable to store the contact's photo
  File? _image;

  Future getImage() async {
    // 사용자가 갤러리에서 이미지를 선택합니다.
    final pickedFile = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 20);

    if (pickedFile != null) {
      // 선택된 이미지를 크롭합니다.
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
      );

      if (croppedFile != null) {
        final imageTemporary = File(croppedFile.path);
        // 파일 크기를 바이트 단위로 얻습니다.
        int fileSizeBytes = await imageTemporary.length();
        // 바이트 단위의 파일 크기를 메가바이트 단위로 변환합니다.
        double fileSizeMb = fileSizeBytes / (1024 * 1024);

        // 콘솔에 이미지 파일의 크기를 프린트합니다.
        print('Cropped image size: ${fileSizeMb.toStringAsFixed(2)} MB');
        // Convert the File to a Uint8List
        Uint8List imageBytes = await imageTemporary.readAsBytes();
        setState(() {
          this._image =
              imageTemporary; // If you still need to use the File somewhere
          this.contactPhoto =
              imageBytes; // Update contactPhoto with the new image
          widget.onPhotoUpdated(
              contactPhoto); // Notify the parent widget of the update
        });
      }
    }
  }

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

  Future<void> _loadInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Load name
    setState(() {
      _nameController.text = (prefs.getString('name') ?? '');
    });

    // Load image
    String? base64Image = prefs.getString('contactPhoto');

    if (base64Image != null) {
      setState(() {
        contactPhoto = base64Decode(base64Image);
      });
    }
  }

  Future<void> _saveInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', _nameController.text);

    // Remove the existing image from SharedPreferences
    await prefs.remove('contactPhoto');

    // If a new image has been selected, save it
    if (contactPhoto != null) {
      String base64Image = base64Encode(contactPhoto!);
      await prefs.setString('contactPhoto', base64Image);
    }
  }

  void _saveAndClose() async {
    // 사용자 정보 업데이트 작업을 시작하지만 완료를 기다리지 않음
    _saveInfo(); // 비동기로 저장 작업 시작
    Provider.of<ProfilePhotoNotifier>(context, listen: false)
        .updatePhoto(contactPhoto);
    // Once the save process is complete, notify the parent widget.
    widget.onPhotoUpdated(contactPhoto);
    int? userPk = await fetchUserPk(); // 사용자 PK 가져오기는 여전히 기다림

    if (userPk != null) {
      if (_nameController.text.isNotEmpty) {
        updateName(userPk, _nameController.text); // 비동기로 이름 업데이트 시작
      }

      if (contactPhoto != null) {
        // 프로필 사진이 변경된 경우 업데이트
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/profile_image.png');
        await file.writeAsBytes(contactPhoto!);
        updatePhoto(userPk, file); // 비동기로 사진 업데이트 시작
      }
    }
    String base64Image = '';
    if (contactPhoto != null) {
      base64Image = base64Encode(contactPhoto!);
    }

    Map<String, dynamic> userInfo = {
      'name': _nameController.text,
      'photo': base64Image,
    };
    // 업데이트 작업을 기다리지 않고 바로 화면 전환
    widget.onboard ? null : Navigator.pop(context, userInfo);
  }

  @override
  Widget build(BuildContext context) {
    var selectedCoursesData = Provider.of<CoursesProvider>(context);
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
          var selectedCoursesData = Provider.of<CoursesProvider>(context);
          return ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            child: Scaffold(
              backgroundColor:
                  widget.onboard ? Colors.transparent : Colors.transparent,
              body: SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                reverse: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (!widget.onboard) {
                          // Ensures that the pop action is performed only when onboard is false
                          Navigator.pop(context); // Pops the current route
                        }
                      },
                      child: Container(
                        height: MediaQuery.of(context).size.height / 1,
                        alignment: Alignment.center,
                      ),
                    ),
                    //assets/icons/profile.svg
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 0, left: 10, right: 10, bottom: 25),
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.onboard
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.background,
                          borderRadius: BorderRadius.all(
                              Radius.circular(30)), // 모서리를 둥글게 만듭니다.
                          // 필요하다면 여기에 그림자나 테두리 등을 추가할 수 있습니다.
                        ),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft:
                                        Radius.circular(20), // 상단 왼쪽 모서리 둥글게
                                    topRight:
                                        Radius.circular(20), // 상단 오른쪽 모서리 둥글게
                                  ),
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    heightFactor:
                                        0.8, // 이미지의 상위 80%만 보여줍니다. 하단 20%는 잘립니다.
                                    child: SvgPicture.asset(
                                      'assets/icons/profile.svg',
                                      width: MediaQuery.of(context).size.width,
                                      // height 설정을 제거하여 전체 이미지 높이를 기준으로 잘립니다.
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      right: 10, bottom: 80),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (widget.onboard == false)
                                        Container(
                                          height: 30,
                                          width: 30,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            shape: BoxShape
                                                .circle, // Ensures the container is circular
                                          ),
                                          child: IconButton(
                                            icon: Icon(
                                              FeatherIcons.x,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outline,
                                              size: 20,
                                            ),

                                            onPressed: () {
                                              if (Navigator.canPop(context)) {
                                                Navigator.pop(context);
                                              }
                                            },
                                            padding: EdgeInsets.all(
                                                5), // Remove padding to fit the icon well
                                            constraints:
                                                BoxConstraints(), // Remove constraints if necessary
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Text(
                              "Edit Your Profile",
                              style: TextStyle(
                                fontSize: 25,
                                color: Theme.of(context).colorScheme.outline,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Set your name and photo!\nThis is what friend see\nwhen you share your schedules",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 95,
                                        height: 95,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.grey,
                                          foregroundColor: Theme.of(context)
                                              .colorScheme
                                              .background,
                                          backgroundImage: contactPhoto != null
                                              ? MemoryImage(contactPhoto!)
                                              : null,
                                          child: contactPhoto == null
                                              ? Image.asset(
                                                  'assets/icons/memoji.png')
                                              : null, // Only show the icon if contactPhoto is null
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: PullDownButton(
                                          itemBuilder: (BuildContext context) {
                                            const PullDownMenuDivider.large();
                                            return <PullDownMenuItem>[
                                              PullDownMenuItem(
                                                title:
                                                    'Get Memoji from Contacts',
                                                subtitle: 'Recommended',
                                                onTap: _pickContact,
                                              ),
                                              PullDownMenuItem(
                                                title: 'Open Photo App',
                                                onTap: getImage,
                                              ),
                                              PullDownMenuItem(
                                                title: 'Use Default Image',
                                                onTap: () async {
                                                  ByteData data =
                                                      await rootBundle.load(
                                                          'assets/icons/memoji.png');
                                                  Uint8List bytes =
                                                      data.buffer.asUint8List();
                                                  setState(() {
                                                    contactPhoto = bytes;
                                                  });
                                                  _saveInfo();
                                                },
                                              ),
                                            ];
                                          },
                                          buttonBuilder: (BuildContext context,
                                              Future<void> Function()
                                                  showMenu) {
                                            return Container(
                                              height: 30,
                                              width: 30,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .background,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .outline,
                                                  width: 2.0,
                                                ),
                                              ),
                                              child: IconButton(
                                                onPressed: showMenu,
                                                icon: Icon(Icons.add),
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .outline,
                                                padding: EdgeInsets.zero,
                                                constraints: BoxConstraints(),
                                                iconSize: 25,
                                              ),
                                            );
                                          },
                                          scrollController: ScrollController(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 20),
                                Text(
                                  _nameController.text.isEmpty
                                      ? "Enter Your Name"
                                      : _nameController.text,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: CupertinoTextField(
                                controller: _nameController,
                                padding: EdgeInsets.all(15),
                                placeholder: "Enter Your Name",
                                placeholderStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .inversePrimary,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                cursorColor:
                                    Theme.of(context).colorScheme.outline,
                                onChanged: (text) {
                                  setState(
                                      () {}); // 텍스트 필드의 내용이 변경될 때마다 UI 업데이트
                                },
                              ),
                            ),
                            SizedBox(height: 20),
                            widget.onboard
                                ? GestureDetector(
                                    onTap: () {
                                      widget.onTap();
                                      _saveAndClose();
                                    },
                                    child: Container(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 20),
                                      height: 55,
                                      width: MediaQuery.of(context).size.width -
                                          80,
                                      decoration: BoxDecoration(
                                          color: Colors.blueAccent,
                                          borderRadius:
                                              BorderRadius.circular(60)),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'NEXT',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: _saveAndClose,
                                    child: Container(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 30),
                                      height: 55,
                                      width: MediaQuery.of(context).size.width -
                                          80,
                                      decoration: BoxDecoration(
                                          color: Colors.blueAccent,
                                          borderRadius:
                                              BorderRadius.circular(60)),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'DONE',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
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
