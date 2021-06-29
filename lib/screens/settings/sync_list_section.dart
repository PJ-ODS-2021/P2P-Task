import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:p2p_task/screens/simple_error_popup_dialog.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/peer_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/widgets/list_section.dart';
import 'package:p2p_task/widgets/simple_dropdown.dart';
import 'package:provider/provider.dart';

class SyncListSection extends StatelessWidget {
  final _intervalOptions = ['off', '1min', '5min', '15min', '1h'];
  final _intervalValues = [0, 60, 300, 900, 3600];

  @override
  Widget build(BuildContext context) {
    final syncService =
        Provider.of<ChangeCallbackNotifier<SyncService>>(context)
            .callbackProvider;
    final peer = Provider.of<ChangeCallbackNotifier<PeerService>>(context)
        .callbackProvider;

    return FutureBuilder<List<dynamic>>(
      future: Future.wait(
        [
          syncService.interval,
          syncService.syncOnStart,
          syncService.syncOnUpdate,
          syncService.retrieveSyncAfterDeviceAdded(),
        ],
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error'),
          );
        }
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
                onChanged: (value) => _setServerStatus(context, peer, value),
              ),
              subtitle: peer.isServerRunning
                  ? Text(
                      'Running on ${peer.serverAddress}:${peer.serverPort}',
                    )
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
                  : _buildIntervalDropdown(syncService, data![0]),
            ),
            ListTile(
              tileColor: Colors.white,
              leading: Icon(Icons.perm_device_info),
              title: Text('Sync on start'),
              trailing: isWaiting
                  ? null
                  : Switch.adaptive(
                      value: data![1],
                      onChanged: (value) => syncService.setSyncOnStart(value),
                    ),
            ),
            ListTile(
              tileColor: Colors.white,
              leading: Icon(Icons.update),
              title: Text('Sync on update'),
              trailing: isWaiting
                  ? null
                  : Switch.adaptive(
                      value: data![2],
                      onChanged: (value) => syncService.setSyncOnUpdate(value),
                    ),
            ),
            ListTile(
              tileColor: Colors.white,
              leading: Icon(Icons.add_to_home_screen),
              title: Text('Sync after device added'),
              trailing: isWaiting
                  ? null
                  : Switch.adaptive(
                      value: data![3],
                      onChanged: (value) =>
                          syncService.setSyncAfterDeviceAdded(value),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIntervalDropdown(SyncService syncService, int interval) {
    return SimpleDropdown(
      items: _intervalOptions,
      initialIndex: _intervalValues.indexWhere((value) => value == interval),
      onItemSelect: (item) async {
        await syncService.setInterval(
          _intervalValues[
              _intervalOptions.indexWhere((option) => option == item)],
        );
      },
    );
  }

  void _setServerStatus(
    BuildContext context,
    PeerService peerService,
    bool startServer,
  ) {
    if (kIsWeb) return;
    if (startServer) {
      peerService.startServer().onError((error, stackTrace) => showDialog(
            context: context,
            builder: (context) => SimpleErrorPopupDialog(
              'Could not start server',
              error.toString(),
            ),
          ));
    } else {
      peerService.stopServer();
    }
  }
}
