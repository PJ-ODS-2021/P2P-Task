import 'package:flutter/material.dart';
import 'package:p2p_task/screens/settings/about_list_section.dart';
import 'package:p2p_task/screens/settings/database_list_section.dart';
import 'package:p2p_task/screens/settings/identity_list_section.dart';
import 'package:p2p_task/screens/settings/network_list_section.dart';
import 'package:p2p_task/screens/settings/sync_list_section.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/database_service.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/peer_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/utils/store_ref_names.dart';
import 'package:p2p_task/widgets/yes_no_dialog.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SyncListSection(),
        IdentityListSection(),
        NetworkListSection(),
        DatabaseSection(),
        AboutListSection(),
        SizedBox(
          height: 36,
        ),
        SizedBox(
          height: 50,
          width: 120,
          child: MaterialButton(
            onPressed: () async => await _handleResetClick(),
            color: Colors.red,
            textColor: Colors.white,
            child: Text('RESET SETTINGS'),
          ),
        ),
      ],
    );
  }

  Future<void> _handleResetClick() async {
    final confirmed =
        await YesNoDialog.show(context, title: 'Reset the settings?') ?? false;
    if (confirmed) {
      final databaseService =
          Provider.of<DatabaseService>(context, listen: false);
      final identityService =
          Provider.of<ChangeCallbackNotifier<IdentityService>>(
        context,
        listen: false,
      ).callbackProvider;
      final peerService = Provider.of<ChangeCallbackNotifier<PeerService>>(
        context,
        listen: false,
      ).callbackProvider;
      final syncService = Provider.of<ChangeCallbackNotifier<SyncService>>(
        context,
        listen: false,
      ).callbackProvider;
      final name = await identityService.name;
      await peerService.stopServer();
      await databaseService.deleteStore(StoreRefNames.settings.value);
      await syncService.setInterval(await syncService.interval);
      await identityService.setName(name!);
      // Used to force a rebuild of the entire settings screen.
      // Otherwise, we would need to invoke the callback notifier
      // of every service that a child widget is dependent on.
      // ignore: no-empty-block
      setState(() {});
    }
  }
}
