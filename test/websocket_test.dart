import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/network/socket_handler.dart';
import 'package:p2p_task/network/messages/debug_message.dart';

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

  test('connects to a custom-made WebSocket server', () async {
    final _registerTypes = (SocketHandler sock) {
      sock.registerTypename<DebugMessage>(
          "DebugMessage", (json) => DebugMessage.fromJson(json));
    };
    const serverMessage = 'hello from the server';
    var receivePort = ReceivePort();

    await Isolate.spawn(startServer, receivePort.sendPort);
    var c = Completer<int>();
    receivePort.listen((message) {
      c.complete(message);
    });
    int port = await c.future;

    var completer = Completer<String>();
    SocketHandler.connect('ws://localhost:$port').then((sock) {
      print('client connected to server');
      _registerTypes(sock);
      sock.registerCallback<DebugMessage>(
          (msg, source) => completer.complete(msg.value));
      sock.send(DebugMessage('hello from the client'));
      return sock.listen().then((sock) {
        return sock;
      });
    });
    var message = await completer.future;

    expect(message, equals(serverMessage));
  });
}
