import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';

const port = 7594;

class TcpServer {
  ServerSocket? _server;

  void start() async {
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    print('TCP server started at ${_server?.address}:${_server?.port}.');

    try {
      _server?.listen((Socket socket) {
        print(
            'New TCP client ${socket.address.address}:${socket.port} connected.');
        socket.writeln("Hello from the echo server!");
        socket.writeln("How are you?");
        socket.listen((Uint8List data) {
          if (data.length > 0 && data.first == 10) return;
          final msg = String.fromCharCodes(data);
          print('Data from client: $msg');
          socket.add(utf8.encode("Echo: "));
          socket.add(data);
        }, onError: (error) {
          print('Error for client ${socket.address.address}:${socket.port}.');
        }, onDone: () {
          print(
              'Connection to client ${socket.address.address}:${socket.port} done.');
        });
      });
    } on SocketException catch (ex) {
      print(ex.message);
    }
  }

  void stop() async {
    await _server?.close();
  }
}
