import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:p2p_task/config/style_constants.dart';
import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/screens/devices/device_form_screen.dart';
import 'package:p2p_task/screens/qr_scanner_screen.dart';
import 'package:p2p_task/screens/qr_code_dialog.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/peer_info_service.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/peer_service.dart';
import 'package:p2p_task/services/device_info_service.dart';
import 'package:p2p_task/utils/log_mixin.dart';
import 'package:p2p_task/services/network_info_service.dart';
import 'package:p2p_task/widgets/list_section.dart';
import 'package:provider/provider.dart';

class DeviceListScreen extends StatefulWidget {
  DeviceListScreen({Key? key}) : super(key: key);

  @override
  _DeviceListScreenState createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> with LogMixin {
  void _onQrCodeRead(
    String qrContent,
    PeerService peerService,
    ConnectionInfo ownInfo,
    BuildContext context,
  ) async {
    var values = qrContent.split(',');

    if (values.length < 5) {
      l.warning(
        'ignoring invalid qr content "$qrContent": less than 6 components',
      );

      return;
    }

    var peerInfo = PeerInfo()
      ..id = values[0]
      ..name = values[1]
      ..locations.add(PeerLocation('ws://${values[2]}:${values[3]}'))
      ..publicKey = values[4];

    await Provider.of<ChangeCallbackNotifier<PeerInfoService>>(context,
            listen: false)
        .callbackProvider
        .upsert(peerInfo);

    var identityService = Provider.of<ChangeCallbackNotifier<IdentityService>>(
      context,
      listen: false,
    ).callbackProvider;

    await peerService.sendIntroductionMessageToPeer(
        ownInfo, peerInfo, await identityService.privateKeyPem,
        location: PeerLocation('ws://${values[3]}:${values[4]}'));
  }

  @override
  Widget build(BuildContext context) {
    final showQrScannerButton = _showQrScannerButton();
    final consumerWidget = Consumer2<ChangeCallbackNotifier<PeerInfoService>,
        ChangeCallbackNotifier<PeerService>>(
      builder: (context, service, peerService, child) => _buildDeviceList(
        context,
        service.callbackProvider,
        peerService.callbackProvider,
        showQrScannerButton,
      ),
    );

    return Stack(
      alignment: const Alignment(0, 0.9),
      children: [
        consumerWidget,
        ElevatedButton(
          onPressed: showQrScannerButton
              ? () => _openQrScanner(context)
              : () => _openDeviceForm(context),
          onLongPress:
              showQrScannerButton ? () => _openDeviceForm(context) : null,
          style: ElevatedButton.styleFrom(
            shape: CircleBorder(),
            padding: EdgeInsets.all(24),
          ),
          child: showQrScannerButton
              ? Icon(Icons.qr_code_scanner)
              : Icon(Icons.add),
        ),
      ],
    );
  }

  Widget _buildDeviceList(
    BuildContext context,
    PeerInfoService service,
    PeerService peerService,
    bool showQrScannerButton,
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
                showQrScannerButton
                    ? Text('Press the button below to scan a QR code.')
                    : Text('Press the button below to add a device.'),
                if (showQrScannerButton)
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
            var identityService =
                Provider.of<ChangeCallbackNotifier<IdentityService>>(
              context,
              listen: false,
            ).callbackProvider;

            await peerService.syncWithPeer(
                peerInfo, await identityService.privateKeyPem,
                location: peerLocation);
          },
        ),
        IconSlideAction(
          caption: 'Delete',
          color: Colors.red.shade400,
          icon: Icons.delete,
          onTap: () => peerInfoService.remove(peerInfo),
        ),
      ],
      child: _buildPeerLocationEntry(peerInfo, peerLocation),
    );
  }

  Widget _buildPeerLocationEntry(
    PeerInfo peerInfo,
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

  Future _openQrScanner(BuildContext context) {
    final peerService = Provider.of<ChangeCallbackNotifier<PeerService>>(
      context,
      listen: false,
    ).callbackProvider;
    final identityService =
        Provider.of<ChangeCallbackNotifier<IdentityService>>(
      context,
      listen: false,
    ).callbackProvider;
    final deviceInfoService =
        Provider.of<DeviceInfoService>(context, listen: false);
    final networkInfoService =
        Provider.of<ChangeCallbackNotifier<NetworkInfoService>>(
      context,
      listen: false,
    ).callbackProvider;

    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrScannerScreen(
          onQRCodeRead: (qrContent) async {
            _onQrCodeRead(
                qrContent,
                peerService,
                ConnectionInfo(
                  selectIp(networkInfoService.ips, await identityService.ip),
                  networkInfoService.ips,
                  await identityService.port,
                  await identityService.name,
                  await identityService.peerId,
                  await identityService.publicKeyPem,
                ),
                context);
          },
        ),
      ),
    );
  }

  Future _openDeviceForm(BuildContext context) async {
    final peerService = Provider.of<ChangeCallbackNotifier<PeerService>>(
      context,
      listen: false,
    ).callbackProvider;
    final identityService =
        Provider.of<ChangeCallbackNotifier<IdentityService>>(
      context,
      listen: false,
    ).callbackProvider;

    final networkInfoService =
        Provider.of<ChangeCallbackNotifier<NetworkInfoService>>(
      context,
      listen: false,
    ).callbackProvider;

    var ownInfo = ConnectionInfo(
      selectIp(networkInfoService.ips, await identityService.ip),
      networkInfoService.ips,
      await identityService.port,
      await identityService.name,
      await identityService.peerId,
      await identityService.publicKeyPem,
    );

    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceFormScreen(peerService, ownInfo),
      ),
    );
  }

  bool _showQrScannerButton() {
    // Dependent on what platforms are supported by qr_code_scanner package.
    // Add more platforms when more support is added.
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return true;
      case TargetPlatform.android:
        return true;
      default:
        return false;
    }
  }

  String? selectIp(List<String> ips, String? storedIp) {
    if (ips.contains(storedIp)) return storedIp;

    return ips.isNotEmpty ? ips.first : null;
  }
}
