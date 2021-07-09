import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:p2p_task/screens/setup/device_setup_screen.dart';
import 'package:p2p_task/screens/setup/setup_screen.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/peer_service.dart';
import 'package:p2p_task/utils/shared_preferences_keys.dart';
import 'package:p2p_task/widgets/fade_route_builder.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServerSetupScreen extends StatefulWidget {
  @override
  _ServerSetupScreenState createState() => _ServerSetupScreenState();
}

class _ServerSetupScreenState extends State<ServerSetupScreen> {
  bool _activateServerGroupValue = true;

  @override
  Widget build(BuildContext context) {
    return SetupScreen(
      title: 'Configure the app Server for data exchange 🔌',
      onSubmit: () => _handleSubmit(context),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Activate server:',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyText1!.color,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 8,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Radio<bool>(
                value: true,
                groupValue: _activateServerGroupValue,
                onChanged: _handleActivateServerChanged,
              ),
              Text('Yes'),
              Radio<bool>(
                value: false,
                groupValue: _activateServerGroupValue,
                onChanged: _handleActivateServerChanged,
              ),
              Text('No'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'To enable other devices to connect with this one '
              'you need the server running.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmit(BuildContext context) async {
    final sharedPreferences =
        Provider.of<SharedPreferences>(context, listen: false);
    await sharedPreferences.setBool(
      SharedPreferencesKeys.activateServer.value,
      _activateServerGroupValue,
    );
    if (_activateServerGroupValue) {
      await Provider.of<ChangeCallbackNotifier<PeerService>>(
        context,
        listen: false,
      ).callbackProvider.startServer();
    }
    await Navigator.pushReplacement(
      context,
      FadeRoute(
        (_) => DeviceSetupScreen(),
      ),
    );
  }

  void _handleActivateServerChanged(bool? value) {
    setState(() {
      _activateServerGroupValue = value ?? true;
    });
  }
}
