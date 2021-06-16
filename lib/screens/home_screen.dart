import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:p2p_task/screens/counter_example_screen.dart';
import 'package:p2p_task/screens/devices/device_list_screen.dart';
import 'package:p2p_task/screens/qr_code_dialog.dart';
import 'package:p2p_task/screens/settings/settings_screen.dart';
import 'package:p2p_task/screens/task_lists_screen.dart';
import 'package:p2p_task/models/task_list.dart';
import 'package:p2p_task/screens/task_list_screen.dart';
import 'package:p2p_task/widgets/bottom_navigation.dart';

class HomeScreen extends StatefulWidget {
  final String title;

  HomeScreen({Key? key, required this.title}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => showDialog(
                context: context, builder: (context) => QrCodeDialog()),
            icon: Icon(Icons.qr_code),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          switch (_selectedIndex) {
            case 0:
              return TaskListsScreen();
            case 1:
              return CounterExampleScreen();
            case 2:
              return DeviceListScreen();
            case 3:
              return SettingsScreen();
          }
          return Center(child: Text('Default.'));
        },
      ),
      bottomNavigationBar: BottomNavigation(
        onTap: (index) => setState(() {
          _selectedIndex = index;
        }),
      ),
    );
  }
}
