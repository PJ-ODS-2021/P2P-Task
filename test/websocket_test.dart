import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/network/messages/debug_message.dart';
import 'package:p2p_task/network/web_socket_peer.dart';
import 'package:p2p_task/security/key_helper.dart';

import 'websocket_server_custom.dart';

void main() {
  var keyHelper = KeyHelper();
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

  // test('connects to a custom-made WebSocketPeer', () async {
  //   const messageContent = 'hello from the server';
  //   var receivePort = ReceivePort();

  //   var keys = keyHelper.generateRSAkeyPair();

  //   await Isolate.spawn(
  //     startServer,
  //     ServerOptions(
  //       sendPort: receivePort.sendPort,
  //       privateKey: keyHelper.encodePrivateKeyToPem(keys.privateKey),
  //       echoDebugMessages: true,
  //       publicKeyForDebugMessage:
  //           keyHelper.encodePublicKeyToPem(keys.publicKey),
  //     ),
  //   );
  //   var serverPortCompleter = Completer<int>();
  //   receivePort.listen((message) {
  //     serverPortCompleter.complete(message as int);
  //   });
  //   var port = await serverPortCompleter.future;

  //   final serverDebugMessageCompleter = Completer<String?>();
  //   final client = WebSocketPeer();
  //   client.registerTypename<DebugMessage>(
  //     'DebugMessage',
  //     (json) => DebugMessage.fromJson(json),
  //   );
  //   client.registerCallback<DebugMessage>((msg, source) {
  //     serverDebugMessageCompleter.complete(msg.value);
  //   });

  //   final publicKeyPem = keyHelper.encodePublicKeyToPem(keys.publicKey);

  //   final sendSucceeded = await client.sendPacketToPeer(
  //     PeerInfo()
  //       ..locations.add(PeerLocation('ws://localhost:$port'))
  //       ..publicKey = publicKeyPem,
  //     DebugMessage(messageContent, publicKeyPem),
  //   );
  //   expect(sendSucceeded, true);
  //   final message = await serverDebugMessageCompleter.future
  //       .timeout(Duration(seconds: 5), onTimeout: () => null);
  //   expect(
  //     message,
  //     isNot(equals(null)),
  //     reason: 'server did not answer within 5s',
  //   );

  //   expect(message, equals(messageContent));
  // });
}
