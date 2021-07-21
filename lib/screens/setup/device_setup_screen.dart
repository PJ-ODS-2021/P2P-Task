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

class DeviceSetupScreen extends StatelessWidget {
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
                            peerInfo.id ?? peerInfo.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(location.uriStr),
                          trailing: IconButton(
                            icon: Icon(Icons.close_rounded),
                            color: Colors.redAccent,
                            onPressed: () => viewModel.removePeerLocation(
                              peerInfo.id,
                              location,
                            ),
                          ),
                        );
                      });
                    })
                    .expand((element) => element)
                    .toList(),
              );
            },
          ),
          Center(
            child: Column(
              children: [
                if (viewModel.showQrScannerButton) ...[
                  TextButton.icon(
                    icon: Icon(Icons.qr_code_scanner_rounded),
                    onPressed: () => _showQRScannerScreen(context, viewModel),
                    label: Text('Scan QR code'),
                  ),
                  Text('or'),
                ],
                TextButton.icon(
                  icon: Icon(Icons.add_rounded),
                  onPressed: () => _showDeviceFormScreen(context),
                  label: Text('Manually add device'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'If you want to synchronize data from another device, you can '
              '${viewModel.showQrScannerButton ? 'scan the devices QR Code' : 'manually add a device'} '
              'now. (You may always do this at a later time.)',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget Function() screenBuilder) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => screenBuilder(),
    ));
  }

  void _showQRScannerScreen(
    BuildContext context,
    DeviceListViewModel viewModel,
  ) {
    _navigateTo(
      context,
      () => QrScannerScreen(onQRCodeRead: viewModel.handleQrCodeRead),
    );
  }

  void _showDeviceFormScreen(BuildContext context) {
    _navigateTo(context, () => DeviceFormScreen());
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
