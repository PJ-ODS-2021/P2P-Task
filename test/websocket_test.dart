import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/network/messages/debug_message.dart';
import 'package:p2p_task/network/web_socket_peer.dart';

import 'websocket_server_custom.dart';

void main() {
  test('connects to a server-side WebSocket', () async {
    var channel = spawnHybridUri('websocket_server.dart');
    var port = await channel.stream.first;
    WebSocket webSocket = await WebSocket.connect('ws://localhost:$port');

    var completer = Completer<String>();
    webSocket.listen((data) {
      completer.complete(data);
    });
    webSocket.close();
    var value = await completer.future;

    expect(value, equals('Hello, world!'));
  });

  test('connects to a custom-made WebSocketPeer', () async {
    const messageContent = 'hello from the server';
    var receivePort = ReceivePort();

    await Isolate.spawn(startServer,
        ServerOptions(sendPort: receivePort.sendPort, echoDebugMessages: true));
    var serverPortCompleter = Completer<int>();
    receivePort
        .listen((message) => serverPortCompleter.complete(message as int));
    int port = await serverPortCompleter.future;

    final serverDebugMessageCompleter = Completer<String?>();
    final client = WebSocketPeer();
    client.registerTypename<DebugMessage>(
        "DebugMessage", (json) => DebugMessage.fromJson(json));
    client.registerCallback<DebugMessage>(
        (msg, source) => serverDebugMessageCompleter.complete(msg.value));
    final bool sendSucceeded = await client.sendPacketToPeer(
        PeerInfo()..locations.add(PeerLocation('ws://localhost:$port')),
        DebugMessage(messageContent));
    expect(sendSucceeded, true);
    final message = await serverDebugMessageCompleter.future
        .timeout(Duration(seconds: 5), onTimeout: () => null);
    expect(message, isNot(equals(null)),
        reason: 'server did not answer within 5s');

    expect(message, equals(messageContent));
  });
}
