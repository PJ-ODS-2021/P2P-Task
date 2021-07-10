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
    RSAPrivateKey privateKey,
  ) async {
    logger.info('Starting initialization of Peer...');
    await _server?.close();
    _server = await WebSocketServer.start(
      port,
      (client) {
        logger.info('a client connected to the server');

        return (client, data) => _handleMessage(client, data, privateKey);
      },
    );
  }

  Future<void> sendPacketToAllPeers<T extends Serializable>(
    T packet, [
    List<PeerInfo> knownPeerInfos = const [],
    RSAPrivateKey? privateKey,
  ]) async {
    final payload = marshallPacket(packet);
    logger.info('sending packet to all peers');

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
    return sendToPeer(
      peerInfo,
      marshallPacket(packet),
      privateKey,
      location: location,
    );
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
      logger.warning('Cannot sync with invalid peer $peerInfo: no locations');

      return false;
    }

    for (final location in peerInfo.locations) {
      final success =
          await _sendToPeerLocation(privateKey, location, encryptedPayload);
      if (success) {
        logger.info('successfully synced with $peerInfo using $location');

        return true;
      }
      logger.info('could not sync with $peerInfo using $location');
    }

    return false;
  }

  Future<bool> _sendToPeerLocation(
    RSAPrivateKey? privateKey,
    PeerLocation location,
    String payload, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    logger.info('Trying to sync with $location...');
    final connection = tryWebSocketClientConnect(location.uri);
    if (connection == null) return false;
    final completer = Completer<bool>();
    connection.dataStream.listen(
      (data) async {
        logger.info('Received message from server:');
        _handleMessage(connection, data, privateKey);

        // for now just always close after having received a message
        unawaited(connection.close());
      },
      onError: (error, stackTrace) {
        completer.complete(false);
        logger.severe(
          'Error listening on websocket data stream to $location',
          error,
          stackTrace,
        );
      },
      onDone: () => completer.complete(true),
    );
    connection.send(payload);
    logger.info('Client sent message to $location');
    Future.delayed(timeout, () {
      logger.info('closing connection to $location due to timeout');
      connection.close();
    });

    return await completer.future;
  }

  WebSocketClient? tryWebSocketClientConnect(Uri uri) {
    try {
      return WebSocketClient.connect(uri);
    } on WebSocketChannelException catch (error, stackTrace) {
      logger.severe(
        'could not create websocket channel to $uri',
        error,
        stackTrace,
      );
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
      logger.severe('missing public key for sending paket');

      return;
    }
    final payload = keyHelper.encrypt(publicKey, marshallPacket(packet));

    logger.info('sending to client');
    client.send(payload);
  }

  void _handleMessage(
    WebSocketClient source,
    String message,
    RSAPrivateKey? privateKey,
  ) {
    Packet? packet;

    if (privateKey == null) {
      logger.warning('Cannot handle message - missing private key.');

      return;
    }

    var payload = '';

    try {
      logger.info('Decrypt message.');
      payload = keyHelper.decrypt(privateKey, message);
    } on Exception catch (e) {
      logger.severe(
        'Could not handle message - could not decrypt received message: $e.',
      );

      return;
    }

    try {
      packet = Packet.fromJson(jsonDecode(payload));
    } on FormatException catch (e) {
      logger.severe('could not decode received json: $e');

      return;
    }

    logger.info('Packet:\n${packet.toJson().toString()}');
    invokeCallback(packet, source);
  }
}
