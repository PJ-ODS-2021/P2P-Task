import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:p2p_task/network/socket_handler.dart';
import 'package:p2p_task/screens/fun_with_sockets/simple_dropdown.dart';
import 'package:p2p_task/screens/qr_reader_screen.dart';
import 'package:p2p_task/services/network_info_service.dart';
import 'package:p2p_task/utils/messages/debug_message.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
  List<String> ips = [];
  String qrContent = '';
  String _serverStatus = 'down';

  Barcode? result;
  QRViewController? controller;

  HttpServer? _server;
  List<SocketHandler> _serverConnections = [];
  SocketHandler? _client;

  final _ipTextController = TextEditingController(text: '');

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      Column(
        children: [
          _buildIpDropdown(context),
          QrImage(
            data: qrContent,
            version: QrVersions.auto,
            size: 200,
          ),
          ElevatedButton(
            onPressed: _serverStatus == 'down'
                ? () => _startServer(_port)
                : _closeServer,
            child: _serverStatus == 'down'
                ? Text('Start Server')
                : Text('Stop Server'),
          ),
          TextFormField(
            controller: _ipTextController,
            decoration: InputDecoration(hintText: 'IP'),
            enabled: true,
            onFieldSubmitted: (value) => _connect(value, _port),
          ),
          _buildQrReaderButton(context),
          TextFormField(
            decoration: InputDecoration(labelText: 'Send a message'),
            onFieldSubmitted: (value) => _sendDebugMessage(value),
          ),
        ],
      )
    ]);
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

  Widget _buildQrReaderButton(BuildContext context) {
    return ElevatedButton(
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
    );
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
    if (_server != null) print('closing server on port ${_server!.port}');
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
