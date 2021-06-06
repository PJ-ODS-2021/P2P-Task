import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:p2p_task/config/style_constants.dart';
import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/network/web_socket_peer.dart';
import 'package:p2p_task/screens/devices/device_form_screen.dart';
import 'package:p2p_task/screens/qr_scanner_screen.dart';
import 'package:p2p_task/services/peer_info_service.dart';
import 'package:p2p_task/services/peer_service.dart';
import 'package:p2p_task/widgets/list_section.dart';
import 'package:provider/provider.dart';

class DeviceListScreen extends StatefulWidget {
  DeviceListScreen({Key? key}) : super(key: key);

  @override
  _DeviceListScreenState createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  _onQrCodeRead(String qrContent, BuildContext context) {
    List<String> values = qrContent.split(',');
    Provider.of<PeerInfoService>(context, listen: false).upsert(
      PeerInfo()
        ..port = int.parse(values[2])
        ..ip = values[1]
        ..id = values[0]
        ..networkName = 'Unknown'
        ..name = values[0],
    );
  }

  @override
  Widget build(BuildContext context) {
    final consumerWidget = Consumer2<PeerInfoService, PeerService>(
      builder: (context, service, peerService, child) =>
          _buildDeviceList(context, service, peerService),
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
          child: Icon(Icons.qr_code_scanner),
          style: ElevatedButton.styleFrom(
            shape: CircleBorder(),
            padding: EdgeInsets.all(24),
          ),
        )
      ],
    );
  }

  Widget _buildDeviceList(
      BuildContext context, PeerInfoService service, PeerService peerService) {
    return FutureBuilder<List<PeerInfo>>(
      future: service.devices,
      initialData: [],
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(
            child: CircularProgressIndicator(),
          );
        if (!snapshot.hasData || snapshot.data!.length < 1) {
          return Center(
              child: Column(
            children: [
              Spacer(),
              Text('📪 No devices yet.', style: kHeroFont),
              Text('Press the button below to scan a QR code.'),
              Text('Longpress the button below to manually add a device.'),
              Spacer(flex: 2),
            ],
          ));
        }
        final networkMap =
            groupBy(snapshot.data!, (PeerInfo entry) => entry.networkName);
        return Column(
          children: networkMap.keys.map((key) {
            return ListSection(
              title: key,
              children: networkMap[key]!.map((e) {
                return _buildSlidablePeerRow(
                  context,
                  service,
                  peerService,
                  e,
                );
              }).toList(),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSlidablePeerRow(BuildContext context, PeerInfoService service,
      PeerService peerService, PeerInfo peerInfo) {
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.20,
      child: _buildPeerEntry(service, peerInfo),
      secondaryActions: <Widget>[
        IconSlideAction(
          caption: 'Sync',
          color: Colors.grey.shade400,
          icon: Icons.sync,
          onTap: () async {
            await peerService.syncWithPeer(peerInfo);
          },
        ),
        IconSlideAction(
          caption: 'Delete',
          color: Colors.red.shade400,
          icon: Icons.delete,
          onTap: () => service.remove(peerInfo),
        ),
      ],
    );
  }

  Widget _buildPeerEntry(PeerInfoService service, PeerInfo peerInfo) {
    return ListTile(
      tileColor: Colors.white,
      leading: Icon(Icons.send_to_mobile),
      title: Text(peerInfo.name.isNotEmpty ? peerInfo.name : peerInfo.id!),
      subtitle: Text(
          'In ${peerInfo.networkName} with ${peerInfo.ip}:${peerInfo.port}'),
      trailing: Icon(Icons.keyboard_arrow_left),
    );
  }
}
