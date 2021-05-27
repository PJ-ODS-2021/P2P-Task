import 'dart:convert';
import 'dart:io';

import 'package:p2p_task/network/packet.dart';
import 'package:p2p_task/network/packet_handler.dart';
import 'package:p2p_task/network/serializable.dart';

class SocketHandler extends PacketHandler {
  final String? url;
  final WebSocket websock;

  SocketHandler(this.websock, [this.url]);

  static Future<SocketHandler> connect(String url) {
    return WebSocket.connect(url).then((value) => SocketHandler(value, url));
  }

  static Future<SocketHandler> upgrade(HttpRequest httpRequest) {
    return WebSocketTransformer.upgrade(httpRequest)
        .then((value) => SocketHandler(value));
  }

  Future<SocketHandler> listen() async {
    print('listening for data....');
    await for (final data in websock) {
      print('received $data from websock');
      var packet = Packet.fromJson(jsonDecode(data));
      invokeCallback(packet);
    }
    print(
        'done listening (reason: ${websock.closeReason}, code: ${websock.closeCode})');
    return this;
  }

  void sendPacket(Packet packet) {
    websock.add(jsonEncode(packet.toJson()));
  }

  void send<T extends Serializable>(T value) {
    sendPacket(toPacket(value));
  }

  Future<void> close([int? code, String? reason]) async {
    return websock.close(code, reason);
  }
}

Future<HttpServer> runServer(int port, Function(SocketHandler) onConnected,
    {Function? onError, Function()? onDone}) async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('running server on ${server.address}:${server.port}');
  server.listen((request) async {
    onConnected(await SocketHandler.upgrade(request));
  }, onError: onError, onDone: onDone);
  return server;
}
