import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:stream_channel/stream_channel.dart';

void hybridMain(StreamChannel channel) async {
  var server = await io.serve(
    webSocketHandler((webSocket) {
      webSocket.sink.add('Hello, world!');
    }),
    'localhost',
    0,
  );

  channel.sink.add(server.port);
}
