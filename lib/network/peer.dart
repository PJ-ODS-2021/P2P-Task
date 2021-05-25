import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:p2p_task/network/socket_handler.dart';
import 'package:p2p_task/utils/messages/debug_message.dart';

void _registerTypes(SocketHandler sock) {
  sock.registerTypename<DebugMessage>(
      "DebugMessage", (json) => DebugMessage.fromJson(json));
}

void _registerServerCallbacks(
    SocketHandler sock, List<String> messages, notifier) {
  sock.registerCallback<DebugMessage>((msg) {
    print('server received debug message "${msg.value}"');
    messages.add('Server received: ${msg.value}');
    notifier();
  });
}

void _registerClientCallbacks(
    SocketHandler sock, List<String> messages, notifier) {
  sock.registerCallback<DebugMessage>((msg) {
    print('client received debug message "${msg.value}"');
    messages.add('Client received: ${msg.value}');
    notifier();
  });
}

class Peer extends ChangeNotifier {
  String _serverStatus = 'down';
  HttpServer? _server;
  List<SocketHandler> _serverConnections = [];
  SocketHandler? _client;

  List<String> _message = [];

  List<String> get messages => List.unmodifiable(_message);

  String get serverStatus => _serverStatus;

  Peer._privateConstructor();
  static final Peer instance = Peer._privateConstructor();

  Future<SocketHandler> connect(String ip, int port) async {
    await _client?.close();
    return SocketHandler.connect('ws://$ip:$port').then((sock) {
      print('client connected to server');
      _client = sock;
      _registerTypes(sock);
      _registerClientCallbacks(sock, _message, notifyListeners);
      sock.send(DebugMessage('hello from the client'));
      return sock.listen().then((sock) {
        _client = null;
        return sock;
      });
    });
  }

  Future<HttpServer> startServer(int port) async {
    await _server?.close();
    return runServer(port, (sock) async {
      print('server got connection from client!');
      _serverConnections.add(sock);
      _registerTypes(sock);
      _registerServerCallbacks(sock, _message, notifyListeners);
      sock.send(DebugMessage('hello from the server'));
      await sock.listen();
      _serverConnections.remove(sock);
      await sock.close();
    }).then((server) {
      _server = server;
      _serverStatus = 'up';
      notifyListeners();
      return server;
    });
  }

  void sendDebugMessage(String message) {
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
      _message.add('Peer sent: $message');
      notifyListeners();
    }
  }

  void closeServer() async {
    if (_server != null) print('closing server on port ${_server!.port}');
    await _server?.close(force: true);
    _server = null;

    for (var client in _serverConnections) {
      await client.close();
    }

    _serverStatus = 'down';
    notifyListeners();
  }

  void closeClient() {
    _client?.close();
    _client = null;
  }

  @override
  void dispose() {
    closeClient();
    closeServer();

    super.dispose();
  }
}
