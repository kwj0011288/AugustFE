import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

typedef ButtonIndexCallback = void Function(int index);

class OneClassPicker extends StatefulWidget {
  final ButtonIndexCallback onButtonPressed;
  const OneClassPicker({Key? key, required this.onButtonPressed})
      : super(key: key);

  @override
  State<OneClassPicker> createState() => _OneClassPickerState();
}

class _OneClassPickerState extends State<OneClassPicker> {
  List<bool> _selections = List.generate(2, (_) => false);
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return buildCenteredButton(context);
  }

  Center buildCenteredButton(BuildContext context) {
    return Center(
      child: ToggleButtons(
        children: [Icon(Icons.circle_outlined), Icon(Icons.cancel)],
        isSelected: _selections,
        onPressed: (int index) {
          setState(() {
            if (_selectedIndex == null || _selectedIndex != index) {
              _selections[_selectedIndex ?? 0] = false;
              _selections[index] = true;
              _selectedIndex = index;
            } else {
              _selections[index] = false;
              _selectedIndex = null;
            }
          });

          widget.onButtonPressed(_selectedIndex ?? -1);
        },
        selectedColor: Colors.black,
        fillColor: Colors.grey,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
