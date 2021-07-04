import 'package:p2p_task/utils/log_mixin.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketClient with LogMixin {
  late WebSocketChannel _channel;

  Stream get dataStream => _channel.stream;

  WebSocketClient.fromChannel(this._channel);

  WebSocketClient.connect(Uri uri) {
    logger.info('Creating WebSocket channel to "$uri"...');
    _channel = WebSocketChannel.connect(uri);
  }

  void send(dynamic payload) {
    _channel.sink.add(payload);
  }

  Future<void> close([int? closeCode, String? closeReason]) async {
    logger.info('Closing WebSocket sink');
    await _channel.sink.close(closeCode, closeReason);
    logger.info('Closed WebSocket sink');
  }
}
