import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TimePickerWidget extends StatefulWidget {
  final Function(DateTime) onTimeSelected;

  const TimePickerWidget({Key? key, required this.onTimeSelected})
      : super(key: key);

  @override
  _TimePickerWidgetState createState() => _TimePickerWidgetState();
}

class _TimePickerWidgetState extends State<TimePickerWidget> {
  DateTime datetime = DateTime(2023, 2, 1, 10, 20);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CupertinoButton(
        padding: EdgeInsets.all(16.0),
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(15),
        onPressed: () {
          showCupertinoModalPopup(
            context: context,
            builder: (BuildContext context) => Container(
              color: const Color(0xFFF7F7F7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFF999999),
                          width: 0.0,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          child: Text('Cancel'),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 5.0,
                          ),
                        ),
                        CupertinoButton(
                          child: Text('Confirm'),
                          onPressed: () {
                            widget.onTimeSelected(datetime);
                            Navigator.pop(context);
                          },
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 5.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 250,
                    child: CupertinoDatePicker(
                      backgroundColor: Color(0xFFF7F7F7),
                      initialDateTime: datetime,
                      onDateTimeChanged: (DateTime newTime) {
                        setState(() => datetime = newTime);
                      },
                      use24hFormat: true,
                      mode: CupertinoDatePickerMode.time,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: Text(
          '${datetime.hour}:${datetime.minute < 10 ? '0' : ''}${datetime.minute}',
          style: TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}
