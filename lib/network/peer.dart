import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:p2p_task/network/messages/debug_message.dart';
import 'package:p2p_task/network/messages/task_list_message.dart';
import 'package:p2p_task/utils/serializable.dart';
import 'package:p2p_task/network/socket_handler.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/utils/log_mixin.dart';

class Peer extends ChangeNotifier with LogMixin {
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
    l.info('connecting to $url');
    return SocketHandler.connect(url).then((sock) {
      l.info('client connected to server');
      _client = sock;
      _registerTypes(sock);
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
      l.info('server got connection from client!');
      _serverConnections.add(sock);
      _registerTypes(sock);
      _registerCommonCallbacks(sock, true, _messageList, notifyListeners);
      sock.send(DebugMessage('hello from the server'));
      await sock.listen();
      l.info('closing client connection');
      _serverConnections.remove(sock);
      await sock.close();
    }, onDone: () {
      l.info('server is done');
      _server = null;
      notifyListeners();
    }, onError: (err) {
      l.warning('server got error: $err');
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
    l.info('sending $msg to server');
    _client!.send(msg);
  }

  void sendToAllClients<T extends Serializable>(T msg) {
    if (_server == null) return;
    l.info(
        'sending message $msg to all clients (${_serverConnections.length})');
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
      l.info('closing server on port ${_server!.port}');
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

  void _registerTypes(SocketHandler sock) {
    sock.registerTypename<DebugMessage>(
        "DebugMessage", (json) => DebugMessage.fromJson(json));
    sock.registerTypename<TaskListMessage>(
        "TaskListMessage", (json) => TaskListMessage.fromJson(json));
  }

  void _registerCommonCallbacks(SocketHandler sock, bool isServer,
      List<String> messages, Function() notifier) async {
    sock.registerCallback<DebugMessage>((msg, source) {
      final socketTypeStr = isServer ? "Server" : "Client";
      l.info('$socketTypeStr received debug message "${msg.value}"');
      messages.add('$socketTypeStr received: ${msg.value}');
      notifier();
    });
    sock.registerCallback<TaskListMessage>((msg, source) async {
      final taskListService = Injector().get<TaskListService>();
      l.info('server task list message');
      taskListService.mergeCrdtJson(msg.taskListCrdtJson);
      if (msg.requestReply) {
        source.send(TaskListMessage(await taskListService.crdtToJson()));
        messages.add('Received task list message and sent reply');
      } else {
        messages.add('Received task list message');
      }
      notifier();
    });
  }
}
