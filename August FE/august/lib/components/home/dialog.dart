import 'package:august/const/font/font.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void showAlertDialog(
  BuildContext context,
  String title,
  String message,
  String leftButton,
  String rightButton,
  bool isOneButton,
  VoidCallback onLeftPressed,
  VoidCallback onRightPressed,
  VoidCallback onMiddlePressed,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: AugustFont.head2(color: Theme.of(context).colorScheme.outline),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style:
              AugustFont.subText2(color: Theme.of(context).colorScheme.outline),
        ),
        actions: <Widget>[
          isOneButton
              ? GestureDetector(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    onMiddlePressed();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    height: 55,
                    width: MediaQuery.of(context).size.width - 80,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          leftButton,
                          style: AugustFont.head4(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onLeftPressed();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        height: 55,
                        width: MediaQuery.of(context).size.width / 3.3,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              leftButton,
                              style: AugustFont.head4(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop(false);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        height: 55,
                        width: MediaQuery.of(context).size.width / 3.3,
                        decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(60)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              rightButton,
                              style: AugustFont.head4(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      );
    },
  );
}

void loadingShowDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Center(
          child: Container(
            width: 100, // Adjust as needed
            height: 100, // Adjust as needed
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(100), // Adjust as needed
            ),
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.outline,
                )),
          ),
        ),
      );
    },
  );
}
