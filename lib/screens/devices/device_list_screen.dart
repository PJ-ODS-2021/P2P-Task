import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:p2p_task/config/style_constants.dart';
import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/screens/devices/device_form_screen.dart';
import 'package:p2p_task/screens/qr_scanner_screen.dart';
import 'package:p2p_task/screens/simple_error_popup_dialog.dart';
import 'package:p2p_task/viewmodels/device_list_viewmodel.dart';
import 'package:p2p_task/widgets/yes_no_dialog.dart';
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

        return _buildPeerInfoList(viewModel, loadProcess.data!);
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

  Widget _buildPeerInfoList(
    DeviceListViewModel viewModel,
    List<PeerInfo> peerInfos,
  ) {
    return ListView(
      children: [
        for (var i = 0; i < peerInfos.length; i++)
          _buildPeerInfoTile(viewModel, peerInfos[i], i),
      ],
    );
  }

  Widget _buildPeerInfoTile(
    DeviceListViewModel viewModel,
    PeerInfo peerInfo,
    int index,
  ) {
    return ExpansionTile(
      title: _buildPeerInfoTitle(viewModel, peerInfo),
      children: peerInfo.locations
          .map((peerLocation) => _buildSlidablePeerRow(
                peerInfo,
                peerLocation,
                viewModel,
              ))
          .toList()
            ..add(_buildAddPeerLocationTile(context, peerInfo)),
    );
  }

  Widget _buildPeerInfoTitle(
    DeviceListViewModel viewModel,
    PeerInfo peerInfo,
  ) {
    return ListTile(
      title: Row(children: [
        _buildPeerInfoStatusIcon(peerInfo),
        SizedBox(width: 5),
        Flexible(
          fit: FlexFit.tight,
          flex: 1,
          child: Text(
            peerInfo.name.isNotEmpty ? peerInfo.name : (peerInfo.id ?? ''),
            textAlign: TextAlign.left,
          ),
        ),
        Spacer(),
        ..._buildSyncOrConnectButton(viewModel, peerInfo),
        SizedBox(width: 5),
        IconButton(
          onPressed: () => YesNoDialog.show(
            context,
            title: 'Delete Device',
            description:
                'Do you really want to delete the device "${peerInfo.name}" with ID "${peerInfo.id}"?',
          ).then((value) {
            if (value != null && value) viewModel.removePeer(peerInfo);
          }),
          tooltip: 'Delete',
          color: Colors.red.shade400,
          icon: Icon(Icons.delete),
        ),
      ]),
      subtitle: peerInfo.id != null
          ? Text(
              'ID: ${peerInfo.id!}',
              style: TextStyle(color: Colors.grey.shade600),
            )
          : null,
    );
  }

  Icon _buildPeerInfoStatusIcon(PeerInfo peerInfo) {
    switch (peerInfo.status) {
      case Status.created:
        return Icon(
          Icons.no_encryption_outlined,
          semanticLabel: 'Inactive',
        );
      case Status.active:
        return Icon(
          Icons.lock_open_outlined,
          semanticLabel: 'Active',
        );
    }
  }

  List<Widget> _buildSyncOrConnectButton(
    DeviceListViewModel viewModel,
    PeerInfo peerInfo,
  ) {
    switch (peerInfo.status) {
      case Status.active:
        return [
          IconButton(
            onPressed: () => _syncWithPeer(context, viewModel, peerInfo),
            tooltip: 'Sync',
            color: Colors.grey.shade500,
            icon: Icon(Icons.sync),
          ),
        ];
      case Status.created:
        return [
          IconButton(
            onPressed: () => _connectToPeer(context, viewModel, peerInfo),
            tooltip: 'Connect',
            color: Colors.yellow.shade700,
            icon: Icon(Icons.settings_ethernet),
          ),
        ];
      default:
        return [];
    }
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
            onTap: () => _syncWithPeer(
              context,
              viewModel,
              peerInfo,
              peerLocation: peerLocation,
            ),
          ),
        if (peerInfo.status == Status.created)
          IconSlideAction(
            caption: 'Connect',
            color: Colors.yellow.shade200,
            icon: Icons.settings_ethernet,
            onTap: () => _connectToPeer(
              context,
              viewModel,
              peerInfo,
              peerLocation: peerLocation,
            ),
          ),
        IconSlideAction(
          caption: 'Delete',
          color: Colors.red.shade400,
          icon: Icons.delete,
          onTap: () => YesNoDialog.show(
            context,
            title: 'Delete Location',
            description:
                'Do you really want to delete the location "${peerLocation.uri}" from the device "${peerInfo.name}" with ID "${peerInfo.id}"?',
          ).then((value) {
            if (value != null && value) {
              viewModel.removePeerLocation(peerInfo.id, peerLocation);
            }
          }),
        ),
      ],
      child: _buildPeerLocationEntry(peerLocation),
    );
  }

  Widget _buildAddPeerLocationTile(BuildContext context, PeerInfo peerInfo) {
    return ListTile(
      leading: Icon(Icons.add),
      title: Text('Add Location'),
      onTap: () => _openDeviceForm(context, template: peerInfo),
    );
  }

  String _listTileTitle(PeerLocation peerLocation) =>
      peerLocation.networkName == null
          ? peerLocation.uriStr
          : '${peerLocation.uriStr} in ${peerLocation.networkName}';

  Widget _buildPeerLocationEntry(PeerLocation peerLocation) {
    return ListTile(
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

  void _syncWithPeer(
    BuildContext context,
    DeviceListViewModel viewModel,
    PeerInfo peerInfo, {
    PeerLocation? peerLocation,
  }) {
    viewModel
        .syncWithPeer(peerLocation == null
            ? peerInfo
            : peerInfo.copyWith(locations: [peerLocation]))
        .then((success) {
      if (!success) {
        showDialog(
          context: context,
          builder: (context) => SimpleErrorPopupDialog(
            'Sync Unsuccessful',
            peerLocation == null
                ? 'Could not sync with "${peerInfo.name}"'
                : 'Could not sync with "${peerInfo.name}" using ${peerLocation.uri}',
          ),
        );
      }
    });
  }

  void _connectToPeer(
    BuildContext context,
    DeviceListViewModel viewModel,
    PeerInfo peerInfo, {
    PeerLocation? peerLocation,
  }) {
    viewModel
        .sendIntroductionMessageToPeer(
      peerLocation == null
          ? peerInfo
          : peerInfo.copyWith(locations: [peerLocation]),
    )
        .then((success) {
      if (!success) {
        showDialog(
          context: context,
          builder: (context) => SimpleErrorPopupDialog(
            'Connection Unsuccessful',
            peerLocation == null
                ? 'Could not connect to "${peerInfo.name}"'
                : 'Could not connect to "${peerInfo.name}" using ${peerLocation.uri}',
          ),
        );
      }
    });
  }
}
