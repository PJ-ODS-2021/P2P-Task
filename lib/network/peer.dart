import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:p2p_task/network/messages/debug_message.dart';
import 'package:p2p_task/network/messages/task_list_message.dart';
import 'package:p2p_task/network/serializable.dart';
import 'package:p2p_task/network/socket_handler.dart';
import 'package:p2p_task/services/task_list_service.dart';

void _registerTypes(SocketHandler sock) {
  sock.registerTypename<DebugMessage>(
      "DebugMessage", (json) => DebugMessage.fromJson(json));
  sock.registerTypename<TaskListMessage>(
      "TaskListMessage", (json) => TaskListMessage.fromJson(json));
}

void _registerServerCallbacks(
    SocketHandler sock, List<String> messages, Function() notifier) {
  sock.registerCallback<DebugMessage>((msg) {
    print('server received debug message "${msg.value}"');

    messages.add('Server received: ${msg.value}');
    notifier();
  });
}

void _registerClientCallbacks(
    SocketHandler sock, List<String> messages, Function() notifier) {
  sock.registerCallback<DebugMessage>((msg) {
    print('client received debug message "${msg.value}"');

    messages.add('Client received: ${msg.value}');
    notifier();
  });
}

void _registerCommonCallbacks(SocketHandler sock, bool isServer,
    List<String> messages, Function() notifier) async {
  sock.registerCallback<TaskListMessage>((msg) async {
    final taskListService = Injector().get<TaskListService>();
    print('server task list message');
    taskListService.mergeCrdtJson(msg.taskListCrdtJson);
    if (msg.requestReply) {
      sock.send(TaskListMessage(await taskListService.crdtToJson()));
      messages.add('Received task list message and sent reply');
    } else {
      messages.add('Received task list message');
    }
    notifier();
  });
}

class Peer extends ChangeNotifier {
  HttpServer? _server;
  List<SocketHandler> _serverConnections = [];
  SocketHandler? _client;

  List<String> _messageList = [];

  List<String> get messages => List.unmodifiable(_messageList);

  bool get serverRunning => _server != null;
  get port => _server?.port;
  get address => _server?.address.address;
  SocketHandler? get client => _client;

  static final Peer _instance = Peer._privateConstructor();

  Peer._privateConstructor();
  factory Peer.instance() => _instance;

  Future<SocketHandler> connect(String ip, int port) async {
    final url = 'ws://$ip:$port';
    await _client?.close();
    print('connecting to $url');
    return SocketHandler.connect(url).then((sock) {
      print('client connected to server');
      _client = sock;
      _registerTypes(sock);
      _registerClientCallbacks(sock, _messageList, notifyListeners);
      _registerCommonCallbacks(sock, false, _messageList, notifyListeners);
      notifyListeners();
      sock.send(DebugMessage('hello from the client'));
      return sock.listen().then((sock) {
        _client = null;
        notifyListeners();
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
      _registerServerCallbacks(sock, _messageList, notifyListeners);
      _registerCommonCallbacks(sock, true, _messageList, notifyListeners);
      sock.send(DebugMessage('hello from the server'));
      await sock.listen();
      print('closing client connection');
      _serverConnections.remove(sock);
      await sock.close();
    }, onDone: () {
      print('server is done');
      _server = null;
      notifyListeners();
    }, onError: (err) {
      print('server got error: $err');
      _server = null;
      notifyListeners();
    }).then((server) {
      _server = server;
      notifyListeners();
      return server;
    });
  }

  void sendToServer<T extends Serializable>(T msg) {
    if (_client == null) return;
    print('sending $msg to server');
    _client!.send(msg);
  }

  void sendToAllClients<T extends Serializable>(T msg) {
    if (_server == null) return;
    print('sending message $msg to all clients (${_serverConnections.length})');
    for (final connection in _serverConnections) {
      connection.send(msg);
    }
  }

  void sendDebugMessage(String message) {
    if (message.isNotEmpty) {
      final messageObj = DebugMessage(message);
      if (_server != null) {
        sendToAllClients(messageObj);
        _messageList.add(
            'Peer sent: "$message" to ${_serverConnections.length} clients');
      }
      if (_client != null) {
        sendToServer(messageObj);
        _messageList.add('Peer sent: "$message" to server');
      }
      notifyListeners();
    }
  }

  void closeServer() async {
    if (_server != null) {
      print('closing server on port ${_server!.port}');
      await _server!.close(force: true);
    }
    await Future.wait([for (var client in _serverConnections) client.close()]);
    notifyListeners();
  }

  void closeClient() async {
    await _client?.close();
    _client = null;
    notifyListeners();
  }

  @override
  void dispose() {
    closeClient();
    closeServer();

    super.dispose();
  }
}
