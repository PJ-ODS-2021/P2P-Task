import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:p2p_task/screens/qr_reader_screen.dart';
import 'package:p2p_task/utils/tcp_client.dart';
import 'package:p2p_task/utils/tcp_server.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FunWithSockets extends StatefulWidget {
  FunWithSockets({Key? key}) : super(key: key);

  @override
  _FunWithSocketsState createState() => _FunWithSocketsState();
}

class _FunWithSocketsState extends State<FunWithSockets> {
  String _connectionStatus = 'Unknown';
  final NetworkInfo _networkInfo = NetworkInfo();

  Barcode? result;
  QRViewController? controller;

  final _server = TcpServer();
  final _client = TcpClient();

  final _ipTextController = TextEditingController(text: '');

  @override
  void initState() {
    super.initState();
    _initNetworkInfo();
  }

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      children: [
        Text('Connection Status: $_connectionStatus'),
        QrImage(
          data: '$_connectionStatus',
          version: QrVersions.auto,
          size: 200,
        ),
        ElevatedButton(
            onPressed: () => _server.start(), child: Text('Start Server')),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _ipTextController,
                decoration: InputDecoration(hintText: 'IP'),
                enabled: true,
                onFieldSubmitted: (value) => _client.connect(value),
              ),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QrReaderScreen(
                      onQRCodeRead: (ip) {
                        _ipTextController..text = ip;
                        _client.connect(ip);
                        setState(() {});
                      },
                    ),
                  ),
                ),
                child: Text('Get IP from QR Code'),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Send a message'),
                onFieldSubmitted: (value) => _sendMessage(value),
              ),
            ],
          ),
        ),
      ],
    ));
  }

  Future<void> _initNetworkInfo() async {
    if (kIsWeb) return;

    String? wifiIP;

    try {
      wifiIP = await _networkInfo.getWifiIP();
      if (wifiIP == "0.0.0.0") {
        for (var interface in await NetworkInterface.list()) {
          wifiIP = interface.addresses[0].address;
          break;
        }
      }
    } on PlatformException catch (e) {
      print(e.toString());
      wifiIP = 'Failed to get Wifi IP';
    }

    setState(() {
      _connectionStatus = '$wifiIP';
    });
  }

  void _sendMessage(String message) {
    if (message.isNotEmpty) {
      _client.send(message);
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    _server.stop();
    _client.close();
    super.dispose();
  }
}
