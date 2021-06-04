import 'package:p2p_task/utils/log_mixin.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketClient with LogMixin {
  WebSocketChannel? _channel;

  WebSocketClient._privateConstructor();
  static final WebSocketClient instance = WebSocketClient._privateConstructor();

  bool get isActive => _channel != null;
  Stream get dataStream => _channel?.stream as Stream;

  void connect(String ip, int port) {
    l.info('Connecting client...');
    _channel = WebSocketChannel.connect(Uri.parse('ws://$ip:$port'));
    l.info('Connected to $ip:$port');
  }

  void send<T>(T payload) {
    if (_channel == null) return;
    _channel!.sink.add(payload);
  }

  Future close() async {
    await _channel?.sink.close();
    _channel = null;
  }
}
