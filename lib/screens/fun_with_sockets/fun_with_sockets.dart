import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:p2p_task/network/peer.dart';
import 'package:p2p_task/screens/fun_with_sockets/simple_dropdown.dart';
import 'package:p2p_task/screens/qr_reader_screen.dart';
import 'package:p2p_task/services/network_info_service.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

const _port = 7594;

class FunWithSockets extends StatefulWidget {
  FunWithSockets({Key? key}) : super(key: key);

  @override
  _FunWithSocketsState createState() => _FunWithSocketsState();
}

class _FunWithSocketsState extends State<FunWithSockets> {
  List<String> ips = [];
  String qrContent = '';

  Barcode? result;
  QRViewController? controller;

  final _ipTextController = TextEditingController(text: '');
  final _sendMessageController = TextEditingController(text: '');

  @override
  Widget build(BuildContext context) {
    return Consumer<Peer>(
      builder: (context, peer, child) => ListView(children: [
        Column(
          children: [
            _buildIpDropdown(context),
            QrImage(
              data: qrContent,
              version: QrVersions.auto,
              size: 200,
            ),
            ElevatedButton(
              onPressed: peer.serverStatus == 'down'
                  ? () => peer.startServer(_port)
                  : peer.closeServer,
              child: peer.serverStatus == 'down'
                  ? Text('Start Server')
                  : Text('Stop Server'),
            ),
            TextFormField(
              controller: _ipTextController,
              decoration: InputDecoration(hintText: 'IP'),
              enabled: true,
              onFieldSubmitted: (value) => peer.connect(value, _port),
            ),
            _buildQrReaderButton(context, peer),
            TextFormField(
              controller: _sendMessageController,
              decoration: InputDecoration(labelText: 'Send a message'),
              onFieldSubmitted: (value) {
                peer.sendDebugMessage(value);
                _sendMessageController.text = '';
              },
            ),
            Column(
              children: peer.messages.reversed.map((e) => Text(e)).toList(),
            ),
          ],
        )
      ]),
    );
  }

  Widget _buildIpDropdown(BuildContext context) {
    return Consumer<NetworkInfoService>(
      builder: (context, service, child) => SimpleDropdown(
          items: service.ips,
          onItemSelect: (ip) => setState(() {
                qrContent = ip;
              })),
    );
  }

  Widget _buildQrReaderButton(BuildContext context, Peer peer) {
    return ElevatedButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QrReaderScreen(
            onQRCodeRead: (ip) {
              peer.connect(ip, _port);
              _ipTextController..text = ip;
            },
          ),
        ),
      ),
      child: Text('Get IP from QR Code'),
    );
  }

  @override
  void dispose() {
    print('disposing...');
    controller?.dispose();
    Peer.instance.closeClient();

    super.dispose();
  }
}
