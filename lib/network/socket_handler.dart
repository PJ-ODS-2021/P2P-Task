import 'dart:convert';
import 'dart:io';
import 'package:p2p_task/network/packet.dart';
import 'package:p2p_task/network/packet_handler.dart';
import 'package:p2p_task/network/serializable.dart';

class SocketHandler extends PacketHandler {
  WebSocket websock;

  SocketHandler(this.websock);

  static Future<SocketHandler> connect(String url) {
    return WebSocket.connect(url).then((value) => SocketHandler(value));
  }

  static Future<SocketHandler> upgrade(HttpRequest httpRequest) {
    return WebSocketTransformer.upgrade(httpRequest)
        .then((value) => SocketHandler(value));
  }

  Future<SocketHandler> listen() async {
    print('listning for data....');
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

Future<HttpServer> runServer(int port,
    [Function(SocketHandler)? onConnected]) async {
  print('running server on port $port');
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  server.listen((request) async {
    final socketHandler = await SocketHandler.upgrade(request);
    if (onConnected != null) {
      onConnected(socketHandler);
    }
  });
  return server;
}
