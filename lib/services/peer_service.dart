import 'package:p2p_task/models/peer_info.dart';
import 'dart:convert';
import 'package:p2p_task/network/messages/debug_message.dart';
import 'package:p2p_task/network/messages/task_list_message.dart';
import 'package:p2p_task/network/peer/web_socket_client.dart';
import 'package:p2p_task/network/messages/introduction_message.dart';
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
    _peer.registerCallback<DebugMessage>(_debugMessageCallback);
    _peer.registerCallback<TaskListMessage>(_taskListMessageCallback);
    _peer.registerCallback<IntroductionMessage>(_introductionMessageCallback);

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
    l.info('Received debug message: ${debugMessage.value}');
  }

  Future<void> _introductionMessageCallback(
    IntroductionMessage introductionMessage,
    WebSocketClient source,
  ) async {
    l.info('Received introduction message');

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
    var peerInfo = PeerInfo()
      ..id = introductionMessage.peerID
      ..name = introductionMessage.name
      ..locations.add(PeerLocation(
          'ws://${introductionMessage.ip}:${introductionMessage.port}'))
      ..publicKeyPem = introductionMessage.publicKey;

    await _peerInfoService.upsert(peerInfo);

    _peer.sendPacketTo(
      source,
      await _getIntroductionMessage(false),
      keyHelper.decodePublicKeyFromPem(peerInfo.publicKeyPem),
    );
  }

  void _handleIntroductionReplyMessage(
    IntroductionMessage introductionMessage,
  ) async {
    var peerInfo = await _peerInfoService.getByID(introductionMessage.peerID);
    if (peerInfo == null) {
      l.warning(
          'Unknown peerID in introduction message ${introductionMessage.peerID} - skipping');

      return;
    }

    // probably should have pendingPeerService and depending on verify delete or accept.
    if (!keyHelper.rsaVerify(peerInfo.publicKeyPem, introductionMessage.peerID,
        introductionMessage.signature)) {
      l.warning('Error message is not from claimed peerID');
    } else {
      l.info('Received introduction reply message');
    }
  }

  Future<void> _taskListMessageCallback(
    TaskListMessage taskListMessage,
    WebSocketClient source,
  ) async {
    var peerInfo = await _peerInfoService.getByID(taskListMessage.peerID);
    if (peerInfo == null) {
      l.warning('Unknown peerID ${taskListMessage.peerID} - skipping');

      return;
    }

    print("SIG:");
    print(taskListMessage.peerID);

    if (!keyHelper.rsaVerify(
      peerInfo.publicKeyPem,
      taskListMessage.peerID,
      taskListMessage.signature,
    )) {
      l.warning('Signature cannot be verified - skipping');

      return;
    }

    l.info('Received TaskListMessage from ${peerInfo.id}');

    await _taskListService.mergeCrdtJson(taskListMessage.taskListCrdtJson);

    if (taskListMessage.requestReply) {
      var taskListCrdtJson = await _taskListService.crdtToJson();
      var privateKey = await _identityService.privateKey;
      var peerID = await _identityService.peerId;

      print(taskListCrdtJson);

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
      l.info('Server received TaskListMessage');
    }
  }

  Future<void> startServer() async {
    final port = await _identityService.port;
    final privateKey = await _identityService.privateKey;
    await _peer.startServer(port, privateKey);
    invokeChangeCallback();
  }

  Future<void> stopServer() async {
    await _peer.stopServer();
    invokeChangeCallback();
  }

  Future<void> syncWithPeer(PeerInfo peerInfo, {PeerLocation? location}) async {
    var message = await _taskListService.crdtToJson();
    var peerID = await _identityService.peerId;
    var privateKey = await _identityService.privateKey;

    final tasksPacket = TaskListMessage(
      message,
      peerID,
      keyHelper.rsaSign(privateKey!, peerID),
      requestReply: true,
    );
    await _peer.sendPacketToPeer(
        peerInfo, await _identityService.privateKey, tasksPacket,
        location: location);
  }

  Future<void> sendIntroductionMessageToPeer(
    PeerInfo peerInfo, {
    PeerLocation? location,
  }) async {
    final message = await _getIntroductionMessage(true);

    await _peer.sendPacketToPeer(
      peerInfo,
      await _identityService.privateKey,
      message,
      location: location,
    );
  }

  Future<IntroductionMessage> _getIntroductionMessage(bool requestReply) async {
    var peerID = await _identityService.peerId;
    var name = await _identityService.name;
    var ip = _selectIp(_networkInfoService.ips, await _identityService.ip);
    var port = await _identityService.port;
    var publicKeyPem = await _identityService.publicKeyPem;
    var privateKey = await _identityService.privateKey;

    return IntroductionMessage(
      peerID,
      name,
      ip,
      port,
      publicKeyPem,
      signature: keyHelper.rsaSign(privateKey!, peerID),
      requestReply: requestReply,
    );
  }

  Future<void> syncWithAllKnownPeers() async {
    var message = await _taskListService.crdtToJson();
    var privateKey = await _identityService.privateKey;
    var peerID = await _identityService.peerId;

    l.info('syncing task list with all known peers');
    final tasksPacket = TaskListMessage(
      message,
      peerID,
      keyHelper.rsaSign(privateKey!, peerID),
      requestReply: true,
    );
    final peers = await _peerInfoService.devices;
    await _peer.sendPacketToAllPeers(
      tasksPacket,
      peers,
      await _identityService.privateKey,
    );
  }

  String _selectIp(List<String> ips, String? storedIp) {
    if (ips.contains(storedIp)) return storedIp!;

    return ips.isNotEmpty ? ips.first : '';
  }
}
