import 'dart:async';

import 'dart:io';

const port = 7594;

class TcpClient {
  Socket? _socket;
  StreamSubscription? _socketStreamSub;
  ConnectionTask<Socket>? _socketConnectionTask;

  void connect(String host) async {
    try {
      _socketConnectionTask = await Socket.startConnect(host, port);
      _socket = await _socketConnectionTask!.socket;

      _socketStreamSub = _socket!.asBroadcastStream().listen((event) {
        print(String.fromCharCodes(event));
      });
      _socket!.handleError((err) {
        print(err);
      });

    } catch (err) {
      print(err);
    }
  }

  void send(String message) {
    _socket?.writeln(message);
  }

  void close() async {
    await _socketStreamSub?.cancel();
    await _socket?.close();
  }
}