import 'dart:isolate';

import 'package:p2p_task/network/messages/debug_message.dart';
import 'package:p2p_task/network/web_socket_peer.dart';

class ServerOptions {
  final SendPort sendPort;
  final int? port;
  final bool echoDebugMessages;

  const ServerOptions(
      {required this.sendPort, this.port, this.echoDebugMessages = false});
}

Future<void> startServer(ServerOptions options) async {
  final peer = WebSocketPeer();
  if (options.echoDebugMessages) {
    peer.registerTypename<DebugMessage>(
        'DebugMessage', (json) => DebugMessage.fromJson(json));
    peer.registerCallback<DebugMessage>(
        (debugMessage, source) => peer.sendPacketTo(source, debugMessage));
  }
  await peer.startServer(options.port ?? 1234);
  options.sendPort.send(peer.serverPort);
}
