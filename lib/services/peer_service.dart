import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/network/messages/debug_message.dart';
import 'package:p2p_task/network/messages/task_list_message.dart';
import 'package:p2p_task/network/peer/web_socket_client.dart';
import 'package:p2p_task/network/messages/introduction_message.dart';
import 'package:p2p_task/network/messages/delete_peer_message.dart';
import 'package:p2p_task/network/web_socket_peer.dart';
import 'package:p2p_task/services/change_callback_provider.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/network_info_service.dart';
import 'package:p2p_task/services/peer_info_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/security/key_helper.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/utils/log_mixin.dart';

class PeerService with LogMixin, ChangeCallbackProvider {
  final WebSocketPeer _peer;
  final TaskListService _taskListService;
  final PeerInfoService _peerInfoService;
  final IdentityService _identityService;
  final NetworkInfoService _networkInfoService;
  final SyncService? _syncService;
  final keyHelper = KeyHelper();

  PeerService(
    this._peer,
    this._taskListService,
    this._peerInfoService,
    this._identityService,
    this._networkInfoService,
    this._syncService,
  ) {
    _peer.clear();

    _peer.registerTypename<DebugMessage>(
      'DebugMessage',
      (json) => DebugMessage.fromJson(json),
    );
    _peer.registerTypename<TaskListMessage>(
      'TaskListMessage',
      (json) => TaskListMessage.fromJson(json),
    );
    _peer.registerTypename<IntroductionMessage>(
      'IntroductionMessage',
      (json) => IntroductionMessage.fromJson(json),
    );
    _peer.registerTypename<DeletePeerMessage>(
      'DeletePeerMessage',
      (json) => DeletePeerMessage.fromJson(json),
    );
    _peer.registerCallback<DebugMessage>(_debugMessageCallback);
    _peer.registerCallback<TaskListMessage>(_taskListMessageCallback);
    _peer.registerCallback<IntroductionMessage>(_introductionMessageCallback);
    _peer.registerCallback<DeletePeerMessage>(_deletePeerMessageCallback);

    _syncService?.startJob(syncWithAllKnownPeers);
    _syncService?.run(runOnSyncOnStart: true);
  }

  bool get isServerRunning => _peer.isServerRunning;

  String? get serverAddress => _peer.serverAddress;

  int? get serverPort => _peer.serverPort;

  void _debugMessageCallback(
    DebugMessage debugMessage,
    WebSocketClient source,
  ) {
    logger.info('Received debug message: ${debugMessage.value}');
  }

  Future<void> _deletePeerMessageCallback(
    DeletePeerMessage deletePeerMessage,
    WebSocketClient source,
  ) async {
    logger
        .info('Received delete peer message from ${deletePeerMessage.peerID}');

    final peerInfo = await _peerInfoService.getById(deletePeerMessage.peerID);
    if (peerInfo == null) {
      logger.warning('Unknown peerID - skipping');

      return;
    }

    if (!keyHelper.rsaVerify(
      peerInfo.publicKeyPem,
      deletePeerMessage.peerID,
      deletePeerMessage.signature,
    )) {
      logger
          .warning('Cannot verify signature of delete peer message - skipping');

      return;
    }

    await _peerInfoService.remove(peerInfo.id);

    return;
  }

  Future<void> _introductionMessageCallback(
    IntroductionMessage introductionMessage,
    WebSocketClient source,
  ) async {
    if (introductionMessage.requestReply) {
      _handleIntroductionMessage(introductionMessage, source);
    } else {
      _handleIntroductionReplyMessage(introductionMessage);
    }
  }

  void _handleIntroductionMessage(
    IntroductionMessage introductionMessage,
    WebSocketClient source,
  ) async {
    logger.info('Received introduction message');

    final peerInfo = PeerInfo(
      id: introductionMessage.peerId,
      name: introductionMessage.name,
      status: Status.active,
      publicKeyPem: introductionMessage.publicKeyPem,
      locations: [
        if (introductionMessage.ip.isNotEmpty)
          PeerLocation(
            'ws://${introductionMessage.ip}:${introductionMessage.port}',
          ),
      ],
    );
    await _peerInfoService.upsert(peerInfo);

    _peer.sendPacketTo(
      source,
      await _makeIntroductionMessage(requestReply: false),
      keyHelper.decodePublicKeyFromPem(peerInfo.publicKeyPem),
    );
  }

  void _handleIntroductionReplyMessage(
    IntroductionMessage introductionMessage,
  ) async {
    logger.info('Received introduction reply message');

    final peerInfo = await _peerInfoService.getById(introductionMessage.peerId);
    if (peerInfo == null) {
      logger.warning(
        'Unknown peerID in introduction message ${introductionMessage.peerId} - skipping',
      );

      return;
    }

    if (!keyHelper.rsaVerify(
      peerInfo.publicKeyPem,
      introductionMessage.peerId,
      introductionMessage.signature,
    )) {
      logger.warning('Error message is not from claimed peerId');
    } else {
      logger.info('Update peer ${peerInfo.status} to active');
      await _peerInfoService.update(
        peerInfo.id,
        (peerInfo) => peerInfo?..status = Status.active,
      );
    }
  }

  Future<void> _taskListMessageCallback(
    TaskListMessage taskListMessage,
    WebSocketClient source,
  ) async {
    final peerInfo = await _peerInfoService.getById(taskListMessage.peerId);
    if (peerInfo == null) {
      logger.warning('Unknown peerID ${taskListMessage.peerId} - skipping');

      return;
    }

    if (!keyHelper.rsaVerify(
      peerInfo.publicKeyPem,
      taskListMessage.peerId,
      taskListMessage.signature,
    )) {
      logger.warning('Signature cannot be verified - skipping');

      return;
    }

    logger.info('Received TaskListMessage from ${peerInfo.id}');

    if (peerInfo.status != Status.active) {
      logger.warning('Peer is not active - skipping');

      return;
    }

    await _taskListService.mergeCrdtJson(taskListMessage.taskListCrdtJson);

    if (taskListMessage.requestReply) {
      final taskListCrdtJson = await _taskListService.crdtToJson();
      final privateKey = await _identityService.privateKey;
      final peerID = await _identityService.peerId;

      final message = TaskListMessage(
        taskListCrdtJson,
        peerID,
        keyHelper.rsaSign(privateKey!, peerID),
      );
      _peer.sendPacketTo(
        source,
        message,
        keyHelper.decodePublicKeyFromPem(peerInfo.publicKeyPem),
      );

      // TODO: propagate new task list through the network using other connected and known peers (if updated)
    } else {
      logger.info('Server received TaskListMessage');
    }
  }

  Future<void> startServer() async {
    final port = await _identityService.port;
    final privateKey = await _identityService.privateKey;
    await _peer.startServer(port, privateKey!);
    invokeChangeCallback();
  }

  Future<void> stopServer() async {
    await _peer.stopServer();
    invokeChangeCallback();
  }

  Future<PeerLocation?> syncWithPeer(PeerInfo peerInfo) async {
    var message = await _taskListService.crdtToJson();
    var peerID = await _identityService.peerId;
    var privateKey = await _identityService.privateKey;

    final tasksPacket = TaskListMessage(
      message,
      peerID,
      keyHelper.rsaSign(privateKey!, peerID),
      requestReply: true,
    );
    final sentLocation = await _peer.sendPacketToPeer(
      peerInfo,
      await _identityService.privateKey,
      tasksPacket,
    );
    if (sentLocation != null) {
      await _movePeerLocationToFront(peerInfo.id, sentLocation);
    }

    return sentLocation;
  }

  /// Returns false if the message could not be sent.
  /// A return value of true does not mean that the message was received by the other peer.
  Future<PeerLocation?> sendIntroductionMessageToPeer(PeerInfo peerInfo) async {
    final sentLocation = await _makeIntroductionMessage(requestReply: true)
        .then((message) async => await _peer.sendPacketToPeer(
              peerInfo,
              await _identityService.privateKey,
              message,
            ))
        .onError((error, stackTrace) async {
      logger.severe('Cannot send introduction message: $error');

      return null;
    });
    if (sentLocation != null) {
      await _movePeerLocationToFront(peerInfo.id, sentLocation);
    }

    return sentLocation;
  }

  Future<void> sendDeletePeerMessageToPeer(PeerInfo peerInfo) async {
    var privateKey = await _identityService.privateKey;
    var peerID = await _identityService.peerId;

    await _peer.sendPacketToPeer(
      peerInfo,
      await _identityService.privateKey,
      DeletePeerMessage(peerID, keyHelper.rsaSign(privateKey!, peerID)),
    );
  }

  Future<IntroductionMessage> _makeIntroductionMessage({
    required bool requestReply,
  }) async {
    final privateKey = await _identityService.privateKey;
    if (privateKey == null) {
      return Future.error(StateError(
        'Cannot make introduction message because private key is null',
      ));
    }
    final peerId = await _identityService.peerId;

    return IntroductionMessage(
      peerId: peerId,
      name: await _identityService.name,
      ip: _selectIp(_networkInfoService.ips, await _identityService.ip),
      port: await _identityService.port,
      publicKeyPem: await _identityService.publicKeyPem,
      signature: keyHelper.rsaSign(privateKey, peerId),
      requestReply: requestReply,
    );
  }

  Future<void> syncWithAllKnownPeers() async {
    final crdtContent = await _taskListService.crdtToJson();
    final privateKey = await _identityService.privateKey;
    final peerID = await _identityService.peerId;

    logger.info('syncing task list with all known peers');
    final tasksPacket = TaskListMessage(
      crdtContent,
      peerID,
      keyHelper.rsaSign(privateKey!, peerID),
      requestReply: true,
    );
    final peers = await _peerInfoService.activeDevices;
    final sendInfo = await _peer.sendPacketToAllPeers(
      tasksPacket,
      peers,
      await _identityService.privateKey,
    );
    await Future.wait(sendInfo
        .where((sendInfo) => sendInfo.peerLocation != null)
        .map((sendInfo) => _movePeerLocationToFront(
              sendInfo.peerInfo.id,
              sendInfo.peerLocation!,
            )));
  }

  String _selectIp(List<String> ips, String? storedIp) {
    if (ips.contains(storedIp)) return storedIp!;

    return ips.isNotEmpty ? ips.first : '';
  }

  Future<void> _movePeerLocationToFront(
    String? peerInfoId,
    PeerLocation location,
  ) async {
    await _peerInfoService.update(peerInfoId, (peerInfo) {
      if (peerInfo == null) return null;
      final index = peerInfo.locations.indexOf(location);
      if (index > 0) {
        peerInfo.locations.removeAt(index);
        peerInfo.locations.insert(0, location);
      }

      return peerInfo;
    });
  }
}
