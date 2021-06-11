import 'dart:isolate';

import 'package:p2p_task/network/messages/debug_message.dart';
import 'package:p2p_task/network/socket_handler.dart';

void _registerTypes(SocketHandler sock) {
  sock.registerTypename<DebugMessage>(
    'DebugMessage',
    (json) => DebugMessage.fromJson(json),
  );
}

void _registerServerCallbacks(SocketHandler sock) {
  sock.registerCallback<DebugMessage>(
    (msg) => print('server received debug message "${msg.value}"'),
  );
}

void startServer(SendPort sendPort) async {
  var server = await runServer(0, (sock) async {
    print('server got connection from client!');
    _registerTypes(sock);
    _registerServerCallbacks(sock);
    sock.send(DebugMessage('hello from the server'));
    await sock.listen();
    await sock.close();
  });

  sendPort.send(server.port);
}
