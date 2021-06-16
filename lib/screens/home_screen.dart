import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:p2p_task/screens/counter_example_screen.dart';
import 'package:p2p_task/screens/devices/device_list_screen.dart';
import 'package:p2p_task/screens/qr_code_dialog.dart';
import 'package:p2p_task/screens/settings/settings_screen.dart';
import 'package:p2p_task/screens/task_list_screen.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/peer_service.dart';
import 'package:p2p_task/widgets/bottom_navigation.dart';
import 'package:provider/provider.dart';

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
          if (!kIsWeb)
            IconButton(
              onPressed: () => _openQrCodeDialog(context),
              icon: Icon(Icons.qr_code),
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          switch (_selectedIndex) {
            case 0:
              return TaskListScreen();
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

  void _openQrCodeDialog(BuildContext context) {
    if (kIsWeb) return;
    final peerService =
        Provider.of<ChangeCallbackNotifier<PeerService>>(context, listen: false)
            .callbackProvider;
    if (!peerService.isServerRunning) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('The server is not running!'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: const [
                      Text('Clients won\'t be able to connect to this device.'),
                      Text('Would you like to start the server now?'),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        peerService.startServer();
                        showDialog(
                            context: context,
                            builder: (context) => QrCodeDialog());
                      },
                      child: Text('Yes')),
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(
                            context: context,
                            builder: (context) => QrCodeDialog());
                      },
                      child: Text('No')),
                ],
              ));
    } else {
      showDialog(context: context, builder: (context) => QrCodeDialog());
    }
  }
}
