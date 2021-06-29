import 'package:flutter/material.dart';
import 'package:p2p_task/screens/settings/database_list_section.dart';
import 'package:p2p_task/screens/settings/identity_list_section.dart';
import 'package:p2p_task/screens/settings/network_list_section.dart';
import 'package:p2p_task/screens/settings/sync_list_section.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SyncListSection(),
        IdentityListSection(),
        NetworkListSection(),
        DatabaseSection(),
      ],
    );
  }
}
