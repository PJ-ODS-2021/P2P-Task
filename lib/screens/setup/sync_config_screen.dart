import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/screens/devices/device_form_screen.dart';
import 'package:p2p_task/screens/home_screen.dart';
import 'package:p2p_task/screens/qr_scanner_screen.dart';
import 'package:p2p_task/screens/setup/config_screen.dart';
import 'package:p2p_task/viewmodels/device_list_viewmodel.dart';
import 'package:p2p_task/widgets/fade_route_builder.dart';
import 'package:provider/provider.dart';

class SyncConfigScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DeviceListViewModel>(context);

    return ConfigScreen(
      title: 'Scan other devices 📱',
      onSubmit: () => _handleSubmit(context),
      child: Column(
        children: [
          ValueListenableBuilder<LoadProcess<List<PeerInfo>>>(
            valueListenable: viewModel.peerInfos,
            builder: (context, loadProcess, child) {
              if (!loadProcess.hasData) {
                return Column(
                  children: [],
                );
              }

              return Column(
                children: loadProcess.data!
                    .map((peerInfo) {
                      return peerInfo.locations.map((location) {
                        return ListTile(
                          title: Text(
                            peerInfo.id?.substring(0, 24).padRight(27, '.') ??
                                peerInfo.name,
                          ),
                          subtitle: Text(location.uriStr),
                        );
                      });
                    })
                    .expand((element) => element)
                    .toList(),
              );
            },
          ),
          Center(
            child: TextButton.icon(
              icon: Icon(Icons.add),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      QrScannerScreen(onQRCodeRead: viewModel.handleQrCodeRead),
                ),
              ),
              onLongPress: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DeviceFormScreen(),
                ),
              ),
              label: Text('Add device'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'If you want to synchronize data from another device, '
              'you can scan the devices QR Code now. (You may always '
              'do this at a later time.)',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmit(BuildContext context) async {
    await Navigator.pushReplacement(
      context,
      FadeRoute(
        (_) => HomeScreen(title: 'P2P Task Manager'),
      ),
    );
  }
}
