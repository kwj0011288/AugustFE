import 'package:august/components/home/button.dart';
import 'package:august/provider/courseprovider.dart';
import 'package:august/components/tile/onboardTile/sem_tile.dart';
import 'package:august/components/tile/onboardTile/univ_tile.dart';
import 'package:august/get_api/onboard/get_semester.dart';
import 'package:august/login/login.dart';
import 'package:august/pages/main/homepage.dart';
import 'package:august/provider/semester_provider.dart';
import 'package:cool_dropdown/models/cool_dropdown_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pull_down_button/pull_down_button.dart';
import "package:flutter_feather_icons/flutter_feather_icons.dart";
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:colorful_safe_area/colorful_safe_area.dart';

class SemesterPage extends StatefulWidget {
  final bool onboard;
  final VoidCallback goBack;
  final VoidCallback gonext;
  SemesterPage({
    Key? key,
    required this.onboard,
    required this.goBack,
    required this.gonext,
  }) : super(key: key);

  @override
  _SemesterPageState createState() => _SemesterPageState();
}

class _SemesterPageState extends State<SemesterPage> {
  late String currentSemetser;

  @override
  void initState() {
    super.initState();
    currentSemetser =
        Provider.of<SemesterProvider>(context, listen: false).semester;
  }

  void _saveAndClose() {
    checkAccessToken();
    Provider.of<SemesterProvider>(context, listen: false).semester =
        currentSemetser;

    widget.onboard ? null : Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    List<String> semestersList =
        Provider.of<SemesterProvider>(context).semestersList;
    return Scaffold(
      body: ColorfulSafeArea(
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
                  if (widget.onboard == true)
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 20, top: 8, bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          widget.goBack();
                          _saveAndClose();
                        },
                        child: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.background,
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
                  Spacer(),
                  if (widget.onboard == false)
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 20, top: 5, bottom: 10),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                        },
                        child: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.background,
                          child: Center(
                            child: Icon(
                              FeatherIcons.x,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (widget.onboard == true) SizedBox(height: 10),
              Text(
                widget.onboard ? "Select Semester" : "Change Semester",
                style: TextStyle(
                  fontSize: 35,
                  color: Theme.of(context).colorScheme.outline,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  "Selected Semester is used for\nCourse search, and Schedule Creation.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 40),
              SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Container(
                  child: Form(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: semestersList.map((semester) {
                        String formattedSemester = formatSemester(semester);
                        return SemesterTile(
                          semester: semester,
                          semesterIcon:
                              "assets/season/${extractSeason(formattedSemester)}.svg",
                          backgroundColor: determineColor(formattedSemester),
                          tileColor: currentSemetser == semester
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary // Selected color
                              : Theme.of(context)
                                  .colorScheme
                                  .primaryContainer, // Default color
                          isShadow: currentSemetser == semester,
                          onTap: () {
                            setState(() {
                              currentSemetser = semester;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
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
                  HapticFeedback.mediumImpact();
                  widget.gonext();
                  _saveAndClose();
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
                onTap: () {
                  _saveAndClose();
                  HapticFeedback.mediumImpact();
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const HomePage(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 200),
                    ),
                  );
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
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
