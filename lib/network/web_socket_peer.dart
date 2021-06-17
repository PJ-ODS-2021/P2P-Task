import 'dart:async';
import 'dart:convert';

import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/network/messages/packet.dart';
import 'package:p2p_task/network/packet_handler.dart';
import 'package:p2p_task/network/peer/web_socket_client.dart';
import 'package:p2p_task/network/peer/web_socket_server.dart';
import 'package:p2p_task/utils/log_mixin.dart';
import 'package:p2p_task/utils/serializable.dart';
import 'package:pedantic/pedantic.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Represents one peer in the network.
class WebSocketPeer with LogMixin, PacketHandler<WebSocketClient> {
  WebSocketServer? _server;

  // Tor now connections to the servers are short-lived and will be closed after the message exchange took place.
  // Therefore, we don't need to store the WebSocketClient as a member variable.

  int? get serverPort => _server?.port;

  String? get serverAddress => _server?.address;

  bool get isServerRunning => _server != null;

  /// Calling this function while it is already running could lead to an error.
  Future<void> startServer(int port) async {
    l.info('Starting initialization of Peer...');
    await _server?.close();
    _server = await WebSocketServer.start(port, (client) {
      l.info('a client connected to the server');

      return _onData;
    });
  }

  void _onData(WebSocketClient client, dynamic data) {
    l.info('Received message from connected peer: $data');
    _handleMessage(client, data);
  }

  Future<void> sendPacketToAllPeers<T extends Serializable>(
    T packet, [
    List<PeerInfo> knownPeerInfos = const [],
  ]) async {
    final payload = marshallPacket(packet);
    l.info('sending packet to all peers');

    // This should implement a broadcast.
    // The difficulty is that clients can be connected to the server and/or have a server running that we can connect to.

    // temporary implementation:
    // _server?.sendToClients(payload);
    knownPeerInfos.forEach((peerInfo) => sendToPeer(peerInfo, payload));
  }

  Future<bool> sendPacketToPeer<T extends Serializable>(
    PeerInfo peerInfo,
    T packet, {
    PeerLocation? location,
  }) async {
    return sendToPeer(peerInfo, marshallPacket(packet), location: location);
  }

  Future<bool> sendToPeer(
    PeerInfo peerInfo,
    String payload, {
    PeerLocation? location,
  }) async {
    // This method doesn't actually need to be async (at least for now).
    // In theory this should use some sort of routing.

    // TODO: should first check if there is an open conncetion to the peer
    // - if not open, try to create connection
    // - if open, use it
    // - if a server is running, it can be used if the peer is currently connected to it

    if (location != null) {
      return _sendToPeerLocation(location, payload);
    }
    if (peerInfo.locations.isEmpty) {
      l.warning('Cannot sync with invalid peer $peerInfo: no locations');

      return false;
    }

    for (final location in peerInfo.locations) {
      final success = await _sendToPeerLocation(location, payload);
      if (success) {
        l.info('successfully synced with $peerInfo using $location');

        return true;
      }
      l.info('could not sync with $peerInfo using $location');
    }

    return false;
  }

  Future<bool> _sendToPeerLocation(
    PeerLocation location,
    String payload, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    l.info('Trying to sync with $location...');
    final connection = tryWebSocketClientConnect(location.uri);
    if (connection == null) return false;
    final completer = Completer<bool>();
    connection.dataStream.listen(
      (data) async {
        l.info('Received message from server: $data');
        _handleMessage(connection, data);

        // for now just always close after having received a message
        unawaited(connection.close());
      },
      onError: (error, stackTrace) {
        completer.complete(false);
        l.severe(
          'Error listening on websocket data stream to $location',
          error,
          stackTrace,
        );
      },
      onDone: () => completer.complete(true),
    );
    connection.send(payload);
    l.info('Client sent message to $location: $payload');
    Future.delayed(timeout, () {
      l.info('closing connection to $location due to timeout');
      connection.close();
    });

    return await completer.future;
  }

  WebSocketClient? tryWebSocketClientConnect(Uri uri) {
    try {
      return WebSocketClient.connect(uri);
    } on WebSocketChannelException catch (error, stackTrace) {
      l.severe('could not create websocket channel to $uri', error, stackTrace);
    }

    return null;
  }

  Future<void> stopServer() async {
    await _server?.close();
    _server = null;
  }

  String marshallPacket<T extends Serializable>(T payload) {
    return jsonEncode(toPacket(payload).toJson());
  }

  void sendPacketTo<T extends Serializable>(WebSocketClient client, T packet) {
    final payload = marshallPacket(packet);
    l.info('sending $payload to client');
    client.send(payload);
  }

  void _handleMessage(WebSocketClient source, String message) {
    Packet? packet;
    try {
      packet = Packet.fromJson(jsonDecode(message));
    } on FormatException catch (e) {
      l.severe('could not decode received json: $e');

      return;
    }
    invokeCallback(packet, source);
  }
}
