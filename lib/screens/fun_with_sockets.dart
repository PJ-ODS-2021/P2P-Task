import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:p2p_task/network/socket_handler.dart';
import 'package:p2p_task/screens/qr_reader_screen.dart';
import 'package:p2p_task/utils/messages/debug_message.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

const _port = 7594;

void _registerTypes(SocketHandler sock) {
  sock.registerTypename<DebugMessage>(
      "DebugMessage", (json) => DebugMessage.fromJson(json));
}

void _registerServerCallbacks(SocketHandler sock) {
  sock.registerCallback<DebugMessage>(
      (msg) => print('server received debug message "${msg.value}"'));
}

void _registerClientCallbacks(SocketHandler sock) {
  sock.registerCallback<DebugMessage>(
      (msg) => print('client received debug message "${msg.value}"'));
}

class FunWithSockets extends StatefulWidget {
  FunWithSockets({Key? key}) : super(key: key);

  @override
  _FunWithSocketsState createState() => _FunWithSocketsState();
}

class _FunWithSocketsState extends State<FunWithSockets> {
  String _connectionStatus = 'Unknown';
  String _serverStatus = 'down';
  final NetworkInfo _networkInfo = NetworkInfo();

  Barcode? result;
  QRViewController? controller;

  HttpServer? _server;
  List<SocketHandler> _serverConnections = [];
  SocketHandler? _client;

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
        Text('Connection Status: $_connectionStatus (server: $_serverStatus)'),
        QrImage(
          data: '$_connectionStatus',
          version: QrVersions.auto,
          size: 200,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () => _startServer(_port),
                child: Text('Start Server')),
            Padding(padding: const EdgeInsets.all(5.0)),
            ElevatedButton(onPressed: _closeServer, child: Text('Stop Server'))
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _ipTextController,
                decoration: InputDecoration(hintText: 'IP'),
                enabled: true,
                onFieldSubmitted: (value) => _connect(value, _port),
              ),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QrReaderScreen(
                      onQRCodeRead: (ip) {
                        _connect(ip, _port);
                        setState(() {
                          _ipTextController..text = ip;
                        });
                      },
                    ),
                  ),
                ),
                child: Text('Get IP from QR Code'),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Send a message'),
                onFieldSubmitted: (value) => _sendDebugMessage(value),
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

  Future<SocketHandler> _connect(String ip, int port) async {
    await _client?.close();
    return SocketHandler.connect('ws://$ip:$port').then((sock) {
      print('client connected to server');
      _client = sock;
      _registerTypes(sock);
      _registerClientCallbacks(sock);
      sock.send(DebugMessage('hello from the client'));
      return sock.listen().then((sock) {
        _client = null;
        return sock;
      });
    });
  }

  Future<HttpServer> _startServer(int port) async {
    await _server?.close();
    return runServer(_port, (sock) async {
      print('server got connection from client!');
      _serverConnections.add(sock);
      _registerTypes(sock);
      _registerServerCallbacks(sock);
      sock.send(DebugMessage('hello from the server'));
      await sock.listen();
      _serverConnections.remove(sock);
      await sock.close();
    }).then((server) {
      _server = server;
      setState(() {
        _serverStatus = "up";
      });
      return server;
    });
  }

  void _sendDebugMessage(String message) {
    if (message.isNotEmpty) {
      final messageObj = DebugMessage(message);
      if (_server != null) {
        print('sending message to all clients (${_serverConnections.length})');
        for (var client in _serverConnections) {
          client.send(messageObj);
        }
      } else if (_client != null) {
        print('sending message to server');
        _client?.send(messageObj);
      }
    }
  }

  void _closeServer() async {
    await _server?.close(force: true);
    _server = null;

    for (var client in _serverConnections) {
      await client.close();
    }

    if (mounted) {
      setState(() {
        _serverStatus = "down";
      });
    }
  }

  @override
  void dispose() {
    print('disposing...');
    controller?.dispose();

    _client?.close();
    _client = null;
    _closeServer();

    super.dispose();
  }
}
