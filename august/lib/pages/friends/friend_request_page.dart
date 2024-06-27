import 'package:august/components/home/button.dart';
import 'package:flutter/widgets.dart';
import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:flutter_feather_icons/flutter_feather_icons.dart";

class FriendsRequestPage extends StatefulWidget {
  const FriendsRequestPage({super.key});

  @override
  State<FriendsRequestPage> createState() => _FriendsRequestPageState();
}

class _FriendsRequestPageState extends State<FriendsRequestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColorfulSafeArea(
        bottomColor: Colors.white.withOpacity(0),
        overflowRules: OverflowRules.all(true),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 10,
                  bottom: 10,
                ),
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 9, 9, 45),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Color.fromARGB(255, 170, 169, 255)),
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 170, 169, 255),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.person_add,
                              color: Color.fromARGB(255, 9, 9, 45),
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Invite Friends on August",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color.fromARGB(255, 170, 169, 255),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "August.app.one/invite",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color.fromARGB(255, 170, 169, 255),
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          Spacer(),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 170, 169, 255),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              FeatherIcons.share,
                              color: Color.fromARGB(255, 9, 9, 45),
                              size: 25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 0),
                child: Center(
                  child: Text(
                    'Do not hesitate to reject or accept friend requests.',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey),
                  ),
                ),
              ),
              SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  height: 90,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey,
                            foregroundColor:
                                Theme.of(context).colorScheme.background,
                            child: Image.asset('assets/icons/memoji.png')),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jay',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          Text(
                            'Sophomore',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.normal,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      Button(
                          onTap: () {},
                          buttonColor: Theme.of(context).colorScheme.background,
                          textColor: Theme.of(context).colorScheme.outline,
                          text: "ACCEPT",
                          width: 80,
                          height: 40,
                          borderColor: Colors.transparent),
                      SizedBox(width: 10),
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
}
