import 'package:flutter/material.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/network_info_service.dart';
import 'package:p2p_task/widgets/list_section.dart';
import 'package:p2p_task/widgets/update_single_value_dialog.dart';
import 'package:pedantic/pedantic.dart';
import 'package:provider/provider.dart';

class NetworkListSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final networkInfoService = Provider.of<NetworkInfoService>(context);
    final identityService = Provider.of<IdentityService>(context);

    return FutureBuilder<List>(
      initialData: [
        'Loading...',
        'Loading...',
        'Loading...',
      ],
      future: Future.wait([
        networkInfoService.ssid,
        identityService.ip,
        identityService.port,
      ]),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error'),
          );
        }
        final data = snapshot.data!;
        final ssid = data[0] ?? 'Unknown';
        final ip = data[1] ?? 'Unknown';
        final port = data[2] ?? 'Unknown';

        return ListSection(
          title: 'Network',
          children: [
            ListTile(
              tileColor: Colors.white,
              leading: Icon(Icons.network_wifi),
              title: Text('Network'),
              subtitle: Text(ssid),
            ),
            ListTile(
              tileColor: Colors.white,
              leading: Icon(Icons.home_outlined),
              title: Text('IP Address'),
              subtitle: Text(ip),
              onTap: () async {
                final result = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    return SimpleDialog(
                      title: Text('Select IP address'),
                      children: networkInfoService.ips
                          .map(
                            (ip) => SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, ip),
                              child: Text(ip),
                            ),
                          )
                          .toList(),
                    );
                  },
                );
                if (result != null && result.isNotEmpty) {
                  unawaited(identityService.setIp(result));
                }
              },
            ),
            ListTile(
              tileColor: Colors.white,
              leading: Icon(Icons.import_export),
              title: Text('Port'),
              subtitle: Text(port.toString()),
              onTap: () => showDialog<int>(
                context: context,
                builder: (context) {
                  return UpdateSingleValueDialog(
                    Text('Set Port'),
                    (portStr) => identityService.setPort(
                      int.parse(portStr),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
