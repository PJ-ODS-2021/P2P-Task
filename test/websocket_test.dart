import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/network/messages/debug_message.dart';
import 'package:p2p_task/network/socket_handler.dart';
import 'package:pedantic/pedantic.dart';

import 'websocket_server_custom.dart';

void main() {
  test('connects to a server-side WebSocket', () async {
    final channel = spawnHybridUri('websocket_server.dart');
    final port = await channel.stream.first;
    final webSocket = await WebSocket.connect('ws://localhost:$port');

    final completer = Completer<String>();
    webSocket.listen((data) {
      completer.complete(data as String);
    });
    await webSocket.close();
    final value = await completer.future;

    expect(value, equals('Hello, world!'));
  });

  test('connects to a custom-made WebSocket server', () async {
    final _registerTypes = (SocketHandler sock) {
      sock.registerTypename<DebugMessage>(
        'DebugMessage',
        (json) => DebugMessage.fromJson(json),
      );
    };
    const serverMessage = 'hello from the server';
    final receivePort = ReceivePort();

    await Isolate.spawn(startServer, receivePort.sendPort);
    final c = Completer<int>();
    receivePort.listen((message) {
      c.complete(message as int);
    });
    final port = await c.future;

    final completer = Completer<String>();
    unawaited(SocketHandler.connect('ws://localhost:$port').then((sock) {
      print('client connected to server');
      _registerTypes(sock);
      sock.registerCallback<DebugMessage>(
        (msg) => completer.complete(msg.value),
      );
      sock.send(DebugMessage('hello from the client'));

      return sock.listen().then((SocketHandler sock) {
        return sock;
      });
    }));
    final message = await completer.future;

    expect(message, equals(serverMessage));
  });
}
