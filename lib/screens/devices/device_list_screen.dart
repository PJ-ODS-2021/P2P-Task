import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:p2p_task/config/style_constants.dart';
import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/screens/devices/device_form_screen.dart';
import 'package:p2p_task/screens/qr_scanner_screen.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/peer_info_service.dart';
import 'package:p2p_task/services/peer_service.dart';
import 'package:p2p_task/utils/log_mixin.dart';
import 'package:p2p_task/widgets/list_section.dart';
import 'package:provider/provider.dart';

class DeviceListScreen extends StatefulWidget {
  DeviceListScreen({Key? key}) : super(key: key);

  @override
  _DeviceListScreenState createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> with LogMixin {
  void _onQrCodeRead(String qrContent, BuildContext context) {
    var values = qrContent.split(',');
    if (values.length < 3) {
      l.warning(
        'ignoring invalid qr content "$qrContent": less than 3 components',
      );

      return;
    }
    Provider.of<ChangeCallbackNotifier<PeerInfoService>>(context, listen: false)
        .callbackProvider
        .upsert(
          PeerInfo()
            ..id = values[0]
            ..name = values[0]
            ..locations.add(PeerLocation('ws://${values[1]}:${values[2]}')),
        );
  }

  @override
  Widget build(BuildContext context) {
    final consumerWidget = Consumer2<ChangeCallbackNotifier<PeerInfoService>,
        ChangeCallbackNotifier<PeerService>>(
      builder: (context, service, peerService, child) => _buildDeviceList(
        context,
        service.callbackProvider,
        peerService.callbackProvider,
      ),
    );

    return Stack(
      alignment: const Alignment(0, 0.9),
      children: [
        consumerWidget,
        ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QrScannerScreen(
                onQRCodeRead: (qrContent) => _onQrCodeRead(qrContent, context),
              ),
            ),
          ),
          onLongPress: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeviceFormScreen(),
            ),
          ),
          style: ElevatedButton.styleFrom(
            shape: CircleBorder(),
            padding: EdgeInsets.all(24),
          ),
          child: Icon(Icons.qr_code_scanner),
        ),
      ],
    );
  }

  Widget _buildDeviceList(
    BuildContext context,
    PeerInfoService service,
    PeerService peerService,
  ) {
    return FutureBuilder<List<PeerInfo>>(
      future: service.devices,
      initialData: [],
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              children: [
                Spacer(),
                Text('📪 No devices yet.', style: kHeroFont),
                Text('Press the button below to scan a QR code.'),
                Text('Longpress the button below to manually add a device.'),
                Spacer(flex: 2),
              ],
            ),
          );
        }
        final peerInfos = snapshot.data!;

        return Column(
          children: peerInfos.map((peerInfo) {
            return ListSection(
              title: peerInfo.name.isNotEmpty ? peerInfo.name : peerInfo.id,
              children: peerInfo.locations.map((peerLocation) {
                return _buildSlidablePeerRow(
                  service,
                  peerService,
                  peerInfo,
                  peerLocation,
                );
              }).toList(),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSlidablePeerRow(
    PeerInfoService peerInfoService,
    PeerService peerService,
    PeerInfo peerInfo,
    PeerLocation peerLocation,
  ) {
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.20,
      secondaryActions: <Widget>[
        IconSlideAction(
          caption: 'Sync',
          color: Colors.grey.shade400,
          icon: Icons.sync,
          onTap: () async {
            await peerService.syncWithPeer(peerInfo, location: peerLocation);
          },
        ),
        IconSlideAction(
          caption: 'Delete',
          color: Colors.red.shade400,
          icon: Icons.delete,
          onTap: () => peerInfoService.remove(peerInfo),
        ),
      ],
      child: _buildPeerLocationEntry(peerInfoService, peerLocation),
    );
  }

  Widget _buildPeerLocationEntry(
    PeerInfoService service,
    PeerLocation peerLocation,
  ) {
    return ListTile(
      tileColor: Colors.white,
      leading: Icon(Icons.send_to_mobile),
      title: Text(peerLocation.networkName == null
          ? peerLocation.uriStr
          : '${peerLocation.uriStr} in ${peerLocation.networkName}'),
      trailing: Icon(Icons.keyboard_arrow_left),
    );
  }
}
