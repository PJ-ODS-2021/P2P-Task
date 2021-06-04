import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:p2p_task/utils/log_mixin.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketServer with LogMixin {
  HttpServer? _server;
  List<WebSocketChannel> _connectedClients = [];

  WebSocketServer._privateConstructor();
  static final WebSocketServer instance = WebSocketServer._privateConstructor();

  bool get isRunning => _server != null;
  get port => _server?.port;
  get address => _server?.address.address;
  get connectedClients => UnmodifiableListView(_connectedClients);

  Future<void> start(int? port,
      {Function(WebSocketChannel)? onConnected,
      Function(WebSocketChannel, dynamic)? onData,
      Function(Error)? onError,
      Function()? onDone}) async {
    await close();
    l.info('Starting server...');
    _server = await serve(webSocketHandler((webSocketChannel) {
      webSocketChannel as WebSocketChannel;
      _connectedClients.add(webSocketChannel);
      if (onConnected != null) onConnected(webSocketChannel);
      if (onData != null)
        webSocketChannel.stream.listen(
          (data) => onData(webSocketChannel, data),
          onError: onError,
          onDone: onDone,
        );
    }), InternetAddress.anyIPv4, port ?? 0);
    l.info('Listening on ${_server!.address}:${_server!.port}');
  }

  void sendToClients<T>(T payload) {
    if (_server == null) return;
    _connectedClients
        .map((client) => client.sink)
        .forEach((sink) => sink.add(payload));
  }

  Future close() async {
    await Future.wait(
        [for (final client in _connectedClients) client.sink.close()]);
    await _server?.close(force: true);
    _server = null;
  }
}
