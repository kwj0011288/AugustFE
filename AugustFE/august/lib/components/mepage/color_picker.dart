import 'package:flutter/material.dart';
import 'package:hsv_color_pickers/hsv_color_pickers.dart';

class ReusableColorPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  const ReusableColorPicker({
    Key? key,
    required this.initialColor,
    required this.onColorChanged,
  }) : super(key: key);

  @override
  _ReusableColorPickerState createState() => _ReusableColorPickerState();
}

class _ReusableColorPickerState extends State<ReusableColorPicker> {
  late Color currentColor;

  @override
  void initState() {
    super.initState();
    currentColor = widget.initialColor;
  }

  void _onColorChange(Color color) {
    setState(() {
      currentColor = color;
    });
    widget.onColorChanged(color);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 10),
        Container(
          width: 230,
          child: HuePicker(
            trackHeight: 45,
            initialColor: HSVColor.fromColor(currentColor),
            onChanged: (color) {
              setState(() {
                currentColor = color.toColor();
              });
              _onColorChange(currentColor);
            },
            thumbShape: HueSliderThumbShape(
              radius: 20,
              color: Colors.white,
              borderColor: Colors.white,
              strokeWidth: 3,
              filled: false,
              showBorder: true,
            ),
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }
}
