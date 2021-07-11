import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:p2p_task/config/style_constants.dart';
import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/screens/devices/device_form_screen.dart';
import 'package:p2p_task/screens/qr_scanner_screen.dart';
import 'package:p2p_task/viewmodels/device_list_viewmodel.dart';
import 'package:p2p_task/widgets/list_section.dart';
import 'package:provider/provider.dart';

class DeviceListScreen extends StatefulWidget {
  DeviceListScreen({Key? key}) : super(key: key);

  @override
  _DeviceListScreenState createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DeviceListViewModel>(context, listen: false);
    viewModel.loadDevices();

    return Stack(
      alignment: const Alignment(0, 0.9),
      children: [
        _buildContent(
          context,
          viewModel,
        ),
        _buildFloatingButton(context, viewModel),
      ],
    );
  }

  Widget _buildFloatingButton(
    BuildContext context,
    DeviceListViewModel viewModel,
  ) {
    return ElevatedButton(
      onPressed: viewModel.showQrScannerButton
          ? () => _openQrScanner(context, viewModel)
          : () => _openDeviceForm(context),
      onLongPress:
          viewModel.showQrScannerButton ? () => _openDeviceForm(context) : null,
      style: ElevatedButton.styleFrom(
        shape: CircleBorder(),
        padding: EdgeInsets.all(24),
      ),
      child: viewModel.showQrScannerButton
          ? Icon(Icons.qr_code_scanner)
          : Icon(Icons.add),
    );
  }

  Widget _buildContent(
    BuildContext context,
    DeviceListViewModel viewModel,
  ) {
    return ValueListenableBuilder<LoadProcess<List<PeerInfo>>>(
      valueListenable: viewModel.peerInfos,
      builder: (context, loadProcess, child) {
        if (loadProcess.hasError) {
          return _buildErrorMessage();
        }
        if (loadProcess.isLoading) {
          return _buildLoadingIndicator();
        }
        if (loadProcess.hasData && loadProcess.data!.isEmpty) {
          return _buildNoDevicesMessage();
        }

        return _buildDeviceList(viewModel, loadProcess.data!);
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '(┬┬﹏┬┬)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 48),
          ),
          SizedBox(
            height: 50,
          ),
          Text(
            'Couldn\'t load data...',
            style: TextStyle(fontSize: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDevicesMessage() {
    return Center(
      child: Column(
        children: [
          Spacer(),
          Text('📪 No devices yet.', style: heroFont),
          Text('Press the button below to scan a QR code.'),
          Text('Longpress the button below to manually add a device.'),
          Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildDeviceList(
    DeviceListViewModel viewModel,
    List<PeerInfo> devices,
  ) {
    return Column(
      children: devices.map((peerInfo) {
        return ListSection(
          title: _getDeviceName(peerInfo),
          children: peerInfo.locations.map((peerLocation) {
            return _buildSlidablePeerRow(
              peerInfo,
              peerLocation,
              viewModel,
            );
          }).toList()
            ..add(_buildAddPeerLocationRow(context, peerInfo)),
        );
      }).toList(),
    );
  }

  String _getDeviceName(PeerInfo peerInfo) {
    final status = peerInfo.status.value;
    final name = peerInfo.name.isNotEmpty ? peerInfo.name : peerInfo.id;

    return '$name - $status';
  }

  Widget _buildSlidablePeerRow(
    PeerInfo peerInfo,
    PeerLocation peerLocation,
    DeviceListViewModel viewModel,
  ) {
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.20,
      secondaryActions: <Widget>[
        if (peerInfo.status == Status.active)
          IconSlideAction(
            caption: 'Sync',
            color: Colors.grey.shade400,
            icon: Icons.sync,
            onTap: () => viewModel
                .syncWithPeer(peerInfo.copyWith(locations: [peerLocation])),
          ),
        if (peerInfo.status == Status.created)
          IconSlideAction(
            caption: 'Connect',
            color: Colors.yellow.shade200,
            icon: Icons.settings_ethernet,
            onTap: () => viewModel.sendIntroductionMessageToPeer(
              peerInfo.copyWith(locations: [peerLocation]),
            ),
          ),
        IconSlideAction(
          caption: 'Delete',
          color: Colors.red.shade400,
          icon: Icons.delete,
          onTap: () => viewModel.removePeerLocation(peerInfo.id, peerLocation),
        ),
      ],
      child: _buildPeerLocationEntry(peerLocation),
    );
  }

  Widget _buildAddPeerLocationRow(BuildContext context, PeerInfo peerInfo) {
    return ListTile(
      tileColor: Colors.white,
      leading: Icon(Icons.add),
      title: Text('Add Peer Location'),
      onTap: () => _openDeviceForm(context, template: peerInfo),
    );
  }

  String _listTileTitle(PeerLocation peerLocation) =>
      peerLocation.networkName == null
          ? peerLocation.uriStr
          : '${peerLocation.uriStr} in ${peerLocation.networkName}';

  Widget _buildPeerLocationEntry(PeerLocation peerLocation) {
    return ListTile(
      tileColor: Colors.white,
      leading: Icon(Icons.send_to_mobile),
      title: Text(_listTileTitle(peerLocation)),
      subtitle: peerLocation.networkName != null
          ? Text('Network: ${peerLocation.networkName}')
          : null,
      trailing: Icon(Icons.keyboard_arrow_left),
    );
  }

  Future _openQrScanner(BuildContext context, DeviceListViewModel viewModel) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrScannerScreen(
          onQRCodeRead: (qrContent) => viewModel.handleQrCodeRead(qrContent),
        ),
      ),
    );
  }

  Future _openDeviceForm(
    BuildContext context, {
    PeerInfo? template,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceFormScreen(template: template),
      ),
    );
  }
}
