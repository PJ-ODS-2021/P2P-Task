import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:p2p_task/network/peer/web_socket_client.dart';
import 'package:p2p_task/utils/log_mixin.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketServer with LogMixin {
  late HttpServer _server;
  final List<WebSocketChannel> _connectedClients = [];

  WebSocketServer._empty();

  static Future<WebSocketServer> start(
    int port,
    Function(WebSocketClient, dynamic)? Function(WebSocketClient)
        createOnDataCallback,
  ) async {
    final server = WebSocketServer._empty();
    server.logger.info('Starting server on port $port...');
    server._server = await serve(
      webSocketHandler((WebSocketChannel channel) {
        server._connectedClients.add(channel);
        final channelClient = WebSocketClient.fromChannel(channel);
        final onDataCallback = createOnDataCallback(channelClient);
        if (onDataCallback != null) {
          channel.stream.listen((data) => onDataCallback(channelClient, data));
        }
      }),
      InternetAddress.anyIPv4,
      port,
    );
    server.logger.info('Listening on ${server.address}:${server.port}');

    return server;
  }

  int get port => _server.port;

  String get address => _server.address.address;

  UnmodifiableListView<WebSocketChannel> get connectedClients =>
      UnmodifiableListView(_connectedClients);

  void sendToClients(dynamic payload) {
    _connectedClients
        .map((client) => client.sink)
        .forEach((sink) => sink.add(payload));
  }

  Future<void> close() async {
    logger.info('stopping server');
    await _server.close(); // stop listening
    await Future.wait([
      for (final client in _connectedClients) client.sink.close(),
    ]); // close connected clients
    await _server.close(
      force: true,
    ); // close every connection that is somehow still open
    logger.info('successfully stopped server');
  }
}
