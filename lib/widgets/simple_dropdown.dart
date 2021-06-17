import 'package:flutter/material.dart';

typedef OnItemSelect = Function(String item);

class SimpleDropdown extends StatefulWidget {
  final List<String> items;
  final int initialIndex;
  final OnItemSelect onItemSelect;

  SimpleDropdown({
    Key? key,
    required this.items,
    this.initialIndex = 0,
    required this.onItemSelect,
  }) : super(key: key);

  @override
  _SimpleDropdownState createState() => _SimpleDropdownState();
}

class _SimpleDropdownState extends State<SimpleDropdown> {
  late String item = widget.items.elementAt(widget.initialIndex);

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: widget.items.isNotEmpty ? item : '',
      icon: const Icon(Icons.arrow_drop_down),
      iconSize: 24,
      elevation: 16,
      style: const TextStyle(color: Colors.deepPurple),
      underline: Container(
        height: 2,
        color: Colors.deepPurpleAccent,
      ),
      onChanged: (String? newValue) {
        setState(() {
          item = newValue!;
          widget.onItemSelect(newValue);
        });
      },
      items: widget.items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
