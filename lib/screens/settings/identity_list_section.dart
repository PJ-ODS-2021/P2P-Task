import 'package:flutter/material.dart';
import 'package:p2p_task/services/device_info_service.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/widgets/list_section.dart';
import 'package:p2p_task/widgets/update_single_value_dialog.dart';
import 'package:provider/provider.dart';

class IdentityListSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final identityService =
        Provider.of<ChangeCallbackNotifier<IdentityService>>(context)
            .callbackProvider;
    final deviceInfoService = Provider.of<DeviceInfoService>(context);

    return ListSection(
      title: 'Identity',
      children: [
        FutureBuilder<String>(
          initialData: 'Loading...',
          future: identityService.peerId,
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return ListTile(
                title: Text('Error'),
              );
            final peerId = snapshot.data!;
            return ListTile(
              tileColor: Colors.white,
              leading: Icon(Icons.perm_identity),
              title: Text('Identifier'),
              subtitle: Text(peerId),
            );
          },
        ),
        FutureBuilder<String>(
          initialData: 'Loading...',
          future: identityService.name,
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return ListTile(
                tileColor: Colors.white,
                title: Text('Error'),
              );
            final name = snapshot.data!;
            return ListTile(
              tileColor: Colors.white,
              leading: Icon(Icons.call_to_action_outlined),
              title: Text('Name'),
              subtitle: Text(name),
              onTap: () => showDialog(
                  context: context,
                  builder: (context) => UpdateSingleValueDialog(
                      Text('Set Name'),
                      (name) => identityService.setName(name))),
            );
          },
        ),
        FutureBuilder<String>(
          initialData: 'Loading...',
          future: deviceInfoService.deviceName,
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return ListTile(
                title: Text('Error'),
              );
            final deviceName = snapshot.data!;
            return ListTile(
              tileColor: Colors.white,
              leading: Icon(Icons.device_unknown),
              title: Text('Device'),
              subtitle: Text(deviceName),
            );
          },
        ),
      ],
    );
  }
}
