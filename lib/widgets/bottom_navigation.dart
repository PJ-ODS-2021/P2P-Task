import 'package:flutter/material.dart';

typedef OnTapCallback = Function(int);

class BottomNavigation extends StatefulWidget {
  final OnTapCallback onTap;

  BottomNavigation({Key? key, required OnTapCallback onTap})
      : onTap = onTap,
        super(key: key);

  @override
  _BottomNavigationState createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.list),
          label: 'Tasks',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.access_time),
          label: 'Activities',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.devices_other),
          label: 'Devices',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.deepPurple[200],
      onTap: _onItemTapped,
    );
  }
}
