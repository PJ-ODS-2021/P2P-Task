import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:p2p_task/network/messages/task_list_message.dart';
import 'package:p2p_task/network/peer.dart';
import 'package:p2p_task/network/socket_handler.dart';
import 'package:p2p_task/screens/qr_scanner_screen.dart';
import 'package:p2p_task/services/network_info_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/widgets/simple_dropdown.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

const _port = 7594;

class DevPlaygroundScreen extends StatefulWidget {
  DevPlaygroundScreen({Key? key}) : super(key: key);

  @override
  _DevPlaygroundScreenState createState() => _DevPlaygroundScreenState();
}

class _DevPlaygroundScreenState extends State<DevPlaygroundScreen> {
  List<String> ips = [];
  String? qrContent;

  Barcode? result;
  QRViewController? controller;

  final _ipTextController = TextEditingController(text: '');
  final _sendMessageController = TextEditingController(text: '');

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      Column(
        children: [
          _buildIpDropdown(context),
          _buildServerInfo(context),
          Divider(),
          _buildConnectToServerWidgets(context),
          _buildConnectedWidgets(context),
          Consumer<Peer>(
            builder: (context, peer, child) => Column(
              children: peer.messages.reversed.map((e) => Text(e)).toList(),
            ),
          ),
        ],
      ),
    ]);
  }

  Widget _buildIpDropdown(BuildContext context) {
    return Consumer<NetworkInfoService>(
      builder: (context, service, child) => SimpleDropdown(
        items: service.ips,
        onItemSelect: (ip) => setState(() => qrContent = ip),
      ),
    );
  }

  Widget _buildServerInfo(BuildContext context) {
    return Consumer<Peer>(
      builder: (context, peer, child) => Column(
        children: [
          Consumer<NetworkInfoService>(
            builder: (context, networkService, child) {
              if (peer.serverRunning) {
                final qrStr = qrContent ??
                    (networkService.ips.isEmpty ? null : networkService.ips[0]);

                return qrStr == null
                    ? Text('Could not find IP')
                    : QrImage(
                        data: qrStr,
                        version: QrVersions.auto,
                        size: 200,
                      );
              } else {
                return Text('Server is not running');
              }
            },
          ),
          ElevatedButton(
            onPressed: !peer.serverRunning
                ? () => peer.startServer(_port)
                : peer.closeServer,
            child:
                peer.serverRunning ? Text('Stop Server') : Text('Start Server'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectToServerWidgets(BuildContext context) {
    return Consumer<Peer>(
      builder: (context, peer, child) => Column(
        children: [
          if (peer.client == null) _buildQrReaderButton(context),
          Row(children: [
            Flexible(
              child: TextFormField(
                controller: _ipTextController,
                decoration: InputDecoration(labelText: 'IP'),
                enabled: peer.client == null,
                validator: (value) =>
                    (value != null && value.isEmpty) ? 'IP is empty' : null,
              ),
            ),
            peer.client == null
                ? ElevatedButton(
                    onPressed: () =>
                        _tryConnect(context, _ipTextController.text, _port),
                    child: Text('Connect'),
                  )
                : ElevatedButton(
                    onPressed: () =>
                        Provider.of<Peer>(context, listen: false).closeClient(),
                    child: Text('Disconnect'),
                  ),
          ]),
          Text(peer.client == null
              ? 'Not connected'
              : 'Connected to ${peer.client!.url ?? "Unknown"}'),
        ],
      ),
    );
  }

  Widget _buildQrReaderButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QrScannerScreen(
            onQRCodeRead: (ip) {
              _ipTextController.text = ip; // no need to call setState
              _tryConnect(context, ip, _port);
            },
          ),
        ),
      ),
      child: Text('Get IP from QR Code'),
    );
  }

  Widget _buildConnectedWidgets(BuildContext context) {
    return Consumer<Peer>(
      builder: (context, peer, child) => Column(
        children: [
          if (child != null && (peer.client != null || peer.serverRunning))
            child,
        ],
      ),
      child: Column(children: [
        TextFormField(
          controller: _sendMessageController,
          decoration: InputDecoration(labelText: 'Send a message'),
          onFieldSubmitted: (value) {
            Provider.of<Peer>(context, listen: false).sendDebugMessage(value);
            _sendMessageController.text = '';
          },
        ),
        ElevatedButton(onPressed: () => _sync(context), child: Text('Sync')),
      ]),
    );
  }

  void _displaySnackBar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: 'Close',
        onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _tryConnect(BuildContext context, String ip, int port) {
    if (ip.isEmpty) return;
    final peer = Provider.of<Peer>(context, listen: false);
    peer.connect(ip, port).catchError(
      (e) {
        var socketException = e as SocketException;
        print('got socket exception: $socketException');
        if (socketException.osError != null) {
          switch (socketException.osError!.errorCode) {
            case -2: // Name or service not known
              _displaySnackBar('Name or service not known');
              break;
            default:
              _displaySnackBar('OS Error: ${socketException.osError}');
          }
        } else {
          _displaySnackBar('Error: $socketException');
        }

        return Future<SocketHandler>.error(e);
      },
      test: (e) => e is SocketException,
    );
  }

  void _sync(BuildContext context) async {
    final peer = Provider.of<Peer>(context, listen: false);
    final msg = TaskListMessage(
      await Provider.of<TaskListService>(context).crdtToJson(),
      requestReply: true,
    );
    peer.sendToAllClients(msg);
    peer.sendToServer(msg);
  }

  @override
  void dispose() {
    print('disposing...');
    controller?.dispose();

    super.dispose();
  }
}
