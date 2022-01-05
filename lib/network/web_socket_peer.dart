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

class PeerInfoAndLocation {
  final PeerInfo peerInfo;
  final PeerLocation? peerLocation;

  const PeerInfoAndLocation(this.peerInfo, this.peerLocation);
}

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

  Future<List<PeerInfoAndLocation>>
      sendPacketToAllPeers<T extends Serializable>(
    T packet,
    Iterable<PeerInfo> peers, {
    RSAPrivateKey? privateKey,
  }) async {
    final payload = marshallPacket(packet);
    logger.info('sending packet to all peers');

    // This should implement a broadcast.
    // The difficulty is that clients can be connected to the server and/or have a server running that we can connect to.

    // temporary implementation:
    // _server?.sendToClients(payload);
    return await Future.wait(peers.map(
      (peerInfo) => sendToPeer(peerInfo, payload, privateKey)
          .then((sentLocation) => PeerInfoAndLocation(peerInfo, sentLocation)),
    ));
  }

  Future<PeerLocation?> sendPacketToPeer<T extends Serializable>(
    PeerInfo peerInfo,
    RSAPrivateKey? privateKey,
    T packet,
  ) async =>
      sendToPeer(peerInfo, marshallPacket(packet), privateKey);

  /// Returns the peer location that was used for the sync
  Future<PeerLocation?> sendToPeer(
    PeerInfo peerInfo,
    String payload,
    RSAPrivateKey? privateKey,
  ) async {
    // This method doesn't actually need to be async (at least for now).
    // In theory this should use some sort of routing.

    // TODO: should first check if there is an open conncetion to the peer
    // - if not open, try to create connection
    // - if open, use it
    // - if a server is running, it can be used if the peer is currently connected to it

    if (peerInfo.locations.isEmpty) {
      logger.warning('Cannot sync with peer $peerInfo: no locations');

      return null;
    }

    final encryptedPayload =
        keyHelper.encryptWithPublicKeyPem(peerInfo.publicKeyPem, payload);
    for (final location in peerInfo.locations) {
      final success =
          await _sendToPeerLocation(privateKey, location, encryptedPayload);
      if (success) {
        logger.info('successfully synced with $peerInfo using $location');

        return location;
      }
      logger.info('could not sync with $peerInfo using $location');
    }

    return null;
  }

  Future<bool> _sendToPeerLocation(
    RSAPrivateKey? privateKey,
    PeerLocation location,
    String payload, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    logger.info('Trying to sync with $location...');
    final connection = tryWebSocketClientConnect(location.uri);
    if (connection == null) return false;
    final completer = Completer<bool>();
    var success = false;
    connection.dataStream.listen(
      (data) async {
        if (completer.isCompleted) return;
        logger.info('Received message from server:');
        success = _handleMessage(connection, data, privateKey);

        // for now just always close after having received a message
        unawaited(connection.close());
      },
      onError: (error, stackTrace) {
        logger.severe(
          'Error listening on websocket data stream to $location',
          error,
          stackTrace,
        );
        if (!completer.isCompleted) completer.complete(false);
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete(success);
      },
    );
    connection.send(payload);
    logger.info('Client sent message to $location');
    Future.delayed(timeout, () {
      logger.info('closing connection to $location due to timeout');
      connection.close();
      if (!completer.isCompleted) completer.complete(false);
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
    } on FormatException catch (error) {
      logger.info('Invalid websocket URI: $error');
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
      logger.severe('missing public key for sending packet');

      return;
    }
    final payload = keyHelper.encrypt(publicKey, marshallPacket(packet));

    logger.info('sending to client');
    client.send(payload);
  }

  /// Return true to signal success
  bool _handleMessage(
    WebSocketClient source,
    String message,
    RSAPrivateKey? privateKey,
  ) {
    Packet? packet;

    if (privateKey == null) {
      logger.warning('Cannot handle message - missing private key.');

      return false;
    }

    var payload = '';
    try {
      logger.info('Decrypt message.');
      payload = keyHelper.decrypt(privateKey, message);
    } on Exception catch (e) {
      logger.severe(
        'Could not handle message - could not decrypt received message: $e.',
      );

      return false;
    }

    try {
      packet = Packet.fromJson(jsonDecode(payload));
    } on FormatException catch (e) {
      logger.severe('could not decode received json: $e');

      return false;
    }

    logger.info('Packet:\n${packet.toJson().toString()}');
    invokeCallback(packet, source);

    return true;
  }
}
