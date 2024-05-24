// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BooleanPicker extends StatefulWidget {
  const BooleanPicker({Key? key}) : super(key: key);

  @override
  _BooleanPickerState createState() => _BooleanPickerState();
}

class _BooleanPickerState extends State<BooleanPicker> {
  String _selectedValueText = 'True';

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      borderRadius: BorderRadius.circular(15),
      padding: const EdgeInsets.all(16.0),
      color: CupertinoColors.white,
      child: Text(
        _selectedValueText,
        style: const TextStyle(fontSize: 18, color: Colors.black),
      ),
      onPressed: () {
        showCupertinoModalPopup(
          context: context,
          builder: (context) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xff999999),
                        width: 0.0,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      CupertinoButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 5.0,
                        ),
                      ),
                      CupertinoButton(
                        child: const Text('Confirm'),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 5.0,
                        ),
                      )
                    ],
                  ),
                ),
                Container(
                  height: 250.0,
                  color: const Color(0xfff7f7f7),
                  child: CupertinoPicker(
                    backgroundColor: const Color(0xfff7f7f7),
                    itemExtent: 28,
                    scrollController:
                        FixedExtentScrollController(initialItem: 0),
                    onSelectedItemChanged: (int index) {
                      setState(() {
                        _selectedValueText = index == 0 ? 'True' : 'False';
                      });
                    },
                    children: [
                      const Text('True'),
                      const Text('False'),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
