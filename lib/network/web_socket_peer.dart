import 'dart:async';
import 'dart:convert';

import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/network/messages/packet.dart';
import 'package:p2p_task/network/packet_handler.dart';
import 'package:p2p_task/network/peer/web_socket_client.dart';
import 'package:p2p_task/network/peer/web_socket_server.dart';
import 'package:p2p_task/security/key_helper.dart';
import 'package:pointycastle/export.dart';
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

  final keyHelper = KeyHelper();

  /// Calling this function while it is already running could lead to an error.
  Future<void> startServer(
    int port,
    RSAPrivateKey? privateKey,
  ) async {
    l.info('Starting initialization of Peer...');
    await _server?.close();
    _server = await WebSocketServer.start(
      port,
      (client, privateKey) {
        l.info('a client connected to the server');

        return _onData;
      },
      privateKey,
    );
  }

  void _onData(
    WebSocketClient client,
    dynamic data,
    RSAPrivateKey? privateKey,
  ) {
    l.info('Received message from connected peer');
    _handleMessage(client, data, privateKey);
  }

  Future<void> sendPacketToAllPeers<T extends Serializable>(
    T packet, [
    List<PeerInfo> knownPeerInfos = const [],
    RSAPrivateKey? privateKey,
  ]) async {
    final payload = marshallPacket(packet);
    l.info('sending packet to all peers');

    // This should implement a broadcast.
    // The difficulty is that clients can be connected to the server and/or have a server running that we can connect to.

    // temporary implementation:
    // _server?.sendToClients(payload);
    await Future.wait(knownPeerInfos.map(
      (peerInfo) => sendToPeer(peerInfo, payload, privateKey),
    ));
  }

  Future<bool> sendPacketToPeer<T extends Serializable>(
    PeerInfo peerInfo,
    RSAPrivateKey? privateKey,
    T packet, {
    PeerLocation? location,
  }) async {
    return sendToPeer(peerInfo, marshallPacket(packet), privateKey,
        location: location);
  }

  Future<bool> sendToPeer(
    PeerInfo peerInfo,
    String payload,
    RSAPrivateKey? privateKey, {
    PeerLocation? location,
  }) async {
    // This method doesn't actually need to be async (at least for now).
    // In theory this should use some sort of routing.

    // TODO: should first check if there is an open conncetion to the peer
    // - if not open, try to create connection
    // - if open, use it
    // - if a server is running, it can be used if the peer is currently connected to it

    var encryptedPayload =
        keyHelper.encryptWithPublicKeyPem(peerInfo.publicKeyPem, payload);

    if (location != null) {
      return _sendToPeerLocation(
        privateKey,
        location,
        encryptedPayload,
      );
    }
    if (peerInfo.locations.isEmpty) {
      l.warning('Cannot sync with invalid peer $peerInfo: no locations');

      return false;
    }

    for (final location in peerInfo.locations) {
      final success =
          await _sendToPeerLocation(privateKey, location, encryptedPayload);
      if (success) {
        l.info('successfully synced with $peerInfo using $location');

        return true;
      }
      l.info('could not sync with $peerInfo using $location');
    }

    return false;
  }

  Future<bool> _sendToPeerLocation(
    RSAPrivateKey? privateKey,
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
        l.info('Received message from server:');
        _handleMessage(connection, data, privateKey);

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
    l.info('Client sent message to $location');
    Future.delayed(timeout, () {
      l.info('closing connection to $location due to timeout');
      connection.close();
    });

    return await completer.future;
  }

  WebSocketClient? tryWebSocketClientConnect(
    Uri uri,
  ) {
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

  void sendPacketTo<T extends Serializable>(
    WebSocketClient client,
    T packet,
    RSAPublicKey? publicKey,
  ) {
    if (publicKey == null) {
      l.severe('missing public key for sending paket');
      return;
    }
    final payload = keyHelper.encrypt(publicKey, marshallPacket(packet));

    l.info('sending to client use key');
    client.send(payload);
  }

  void _handleMessage(
    WebSocketClient source,
    String message,
    RSAPrivateKey? privateKey,
  ) {
    Packet? packet;

    if (privateKey == null) {
      l.warning('canot handle message - missing pirvatekey');

      return;
    }

    var payload = '';

    try {
      l.info('decrypt message');
      payload = keyHelper.decrypt(privateKey, message);
    } on Exception catch (e) {
      l.severe('canot handle message - could not decrypt received message: $e');

      return;
    }

    try {
      packet = Packet.fromJson(jsonDecode(payload));
    } on FormatException catch (e) {
      l.severe('could not decode received json: $e');

      return;
    }

    invokeCallback(packet, source);
  }
}
