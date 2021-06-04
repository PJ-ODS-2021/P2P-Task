import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:p2p_task/network/web_socket_peer.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/widgets/list_section.dart';
import 'package:p2p_task/widgets/simple_dropdown.dart';
import 'package:provider/provider.dart';

class SyncListSection extends StatelessWidget {
  final _intervalOptions = ['off', '1s', '5s', '10s', '15s', '30s', '60s'];

  @override
  Widget build(BuildContext context) {
    final syncService = Provider.of<SyncService>(context);
    final peer = Provider.of<WebSocketPeer>(context);

    return FutureBuilder<List<dynamic>>(
        future: Future.wait([
          syncService.interval,
          syncService.syncOnStart,
          syncService.syncOnUpdate
        ]),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(
              child: Text('Error'),
            );
          final isWaiting = snapshot.connectionState != ConnectionState.done;
          final data = snapshot.data;
          return ListSection(
            title: 'Synchronization',
            children: [
              ListTile(
                tileColor: Colors.white,
                title: Text('Activate server'),
                leading: Icon(Icons.electrical_services),
                trailing: Switch.adaptive(
                  value: peer.isServerRunning,
                  onChanged: kIsWeb
                      ? (value) => null
                      : (value) => value ? peer.start() : peer.stopServer(),
                ),
                subtitle: peer.isServerRunning
                    ? Text('Running on ${peer.address}:${peer.port}')
                    : kIsWeb
                        ? Text('Web not supported')
                        : Text('Not running'),
              ),
              ListTile(
                tileColor: Colors.white,
                leading: Icon(Icons.sync),
                title: Text('Sync interval'),
                trailing: isWaiting
                    ? null
                    : SimpleDropdown(
                        items: _intervalOptions,
                        initialIndex: data![0] == 0
                            ? 0
                            : _intervalOptions.indexWhere(
                                (option) => option == '${data[0]}s'),
                        onItemSelect: (item) async {
                          await syncService.setInterval(item == 'off'
                              ? 0
                              : int.parse(item.replaceAll('s', '')));
                        },
                      ),
              ),
              ListTile(
                tileColor: Colors.white,
                leading: Icon(Icons.perm_device_info),
                title: Text('Sync on start'),
                trailing: isWaiting
                    ? null
                    : Switch.adaptive(
                        value: data![1],
                        onChanged: (value) =>
                            syncService.setSyncOnStart(value)),
              ),
              ListTile(
                tileColor: Colors.white,
                leading: Icon(Icons.update),
                title: Text('Sync on update'),
                trailing: isWaiting
                    ? null
                    : Switch.adaptive(
                        value: data![2],
                        onChanged: (value) =>
                            syncService.setSyncOnUpdate(value)),
              ),
            ],
          );
        });
  }
}
