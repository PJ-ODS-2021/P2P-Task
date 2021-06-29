import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/network/messages/debug_message.dart';
import 'package:p2p_task/network/messages/task_list_message.dart';
import 'package:p2p_task/network/messages/introduction_message.dart';
import 'package:p2p_task/network/messages/task_lists_message.dart';
import 'package:p2p_task/network/peer/web_socket_client.dart';
import 'package:p2p_task/network/web_socket_peer.dart';
import 'package:p2p_task/services/change_callback_provider.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/peer_info_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/screens/qr_code_dialog.dart';
import 'package:p2p_task/security/key_helper.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/services/task_lists_service.dart';
import 'package:p2p_task/utils/log_mixin.dart';

class PeerService with LogMixin, ChangeCallbackProvider {
  final WebSocketPeer _peer;
  final TaskListService _taskListService;
  final TaskListsService _taskListsService;
  final PeerInfoService _peerInfoService;
  final IdentityService _identityService;
  final SyncService _syncService;
  final keyHelper = KeyHelper();

  PeerService(
    this._peer,
    this._taskListService,
    this._taskListsService,
    this._peerInfoService,
    this._identityService,
    this._syncService,
  ) {
    _peer.clear();

    _peer.registerTypename<DebugMessage>(
      'DebugMessage',
      (json) => DebugMessage.fromJson(json),
    );
    _peer.registerTypename<TaskListsMessage>(
      'TaskListsMessage',
      (json) => TaskListsMessage.fromJson(json),
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
    _peer.registerCallback<TaskListsMessage>(_taskListsMessageCallback);
    _peer.registerCallback<TaskListMessage>(_taskListMessageCallback);
    _peer.registerCallback<IntroductionMessage>(_introductionMessageCallback);

    // don't know how to handle privatekey
    // _syncService
    //     .startJob(syncWithAllKnownPeers();
    _syncService.run(runOnSyncOnStart: true);
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
    l.info('Received introduction message: ${introductionMessage.message}');

    if (introductionMessage.requestReply) {
      _handleIntroductionMessage(introductionMessage, source);
    } else {
      _handleIntroductionReplyMessage(introductionMessage.message);
    }
  }

  void _handleIntroductionMessage(
    IntroductionMessage introductionMessage,
    WebSocketClient source,
  ) async {
    var values = introductionMessage.message.split(': ');

    if (values.length < 2) {
      l.warning(
        'ignoring invalid intoduction message "$values": missing informations',
      );

      return;
    }

    values = values[1].split(',');

    if (values.length < 5) {
      l.warning(
        'ignoring invalid intoduction message "$values": less than 5 components',
      );

      return;
    }

    var publicKey = values[4].substring(0, values[4].length - 1);

    var peerInfo = PeerInfo()
      ..id = values[0]
      ..name = values[1]
      ..locations.add(PeerLocation('ws://${values[2]}:${values[3]}'))
      ..publicKey = publicKey;

    await _peerInfoService.upsert(peerInfo);

    var peerID = await _identityService.peerId;
    var name = await _identityService.name;

    _peer.sendPacketTo(
      source,
      IntroductionMessage('Hello back from $name,$peerID'),
      publicKey,
    );
  }

  void _handleIntroductionReplyMessage(String encryptedMessage) async {
    //encofing error of privateKey;
    var message = keyHelper.decryptWithPrivateKeyPem(
        await _identityService.privateKeyPem, encryptedMessage);

    if (!message.contains('Hello back from')) {
      l.warning(
          'Error decrypting reply of introduction message, expected \'Hello back from ...\' but retrieved $message');
    } else {
      l.info('Received introduction reply message: $message');
    }
  }

  Future<void> _taskListMessageCallback(
    TaskListMessage taskListMessage,
    WebSocketClient source,
  ) async {
    l.info('Received TaskListMessage');
    await _taskListService.mergeCrdtJson(taskListMessage.taskListCrdtJson);
    if (taskListMessage.requestReply) {
      final taskListCrdtJson = await _taskListService.crdtToJson();
      _peer.sendPacketTo(
          source,
          TaskListMessage(taskListCrdtJson, taskListMessage.publicKey),
          taskListMessage.publicKey);

      // TODO: propagate new task list through the network using other connected and known peers (if updated)
    } else {
      l.info('Server received TaskListMessage');
    }
  }

  Future<void> _taskListsMessageCallback(
    TaskListsMessage taskListsMessage,
    WebSocketClient source,
  ) async {
    l.info(
      'Received TaskListsMessage',
    );
    await _taskListsService.mergeCrdtJson(taskListsMessage.taskListsCrdtJson);
    if (taskListsMessage.requestReply) {
      final taskListCrdtJson = await _taskListsService.crdtToJson();
      source.publicKey = taskListsMessage.publicKey;
      _peer.sendPacketTo(
        source,
        TaskListsMessage(taskListCrdtJson, taskListsMessage.publicKey),
        taskListsMessage.publicKey,
      );

      // TODO: propagate new task lists through the network using other connected and known peers (if updated)
    } else {
      l.info('Server received TaskListsMessage');
    }
  }

  Future<void> startServer() async {
    final port = await _identityService.port;
    final privateKey = await _identityService.privateKeyPem;
    await _peer.startServer(port, privateKey);
    invokeChangeCallback();
  }

  Future<void> stopServer() async {
    await _peer.stopServer();
    invokeChangeCallback();
  }

  Future<void> syncWithPeer(PeerInfo peerInfo, String privateKey,
      {PeerLocation? location}) async {
    final packetTasks = TaskListMessage(
      await _taskListService.crdtToJson(),
      peerInfo.publicKey,
      requestReply: true,
    );
    final packetLists = TaskListsMessage(
      await _taskListsService.crdtToJson(),
      peerInfo.publicKey,
      requestReply: true,
    );

    await _peer.sendPacketToPeer(peerInfo, privateKey, packetLists,
        location: location);
    await _peer.sendPacketToPeer(peerInfo, privateKey, packetTasks,
        location: location);
  }

  Future<void> sendIntroductionMessageToPeer(
      ConnectionInfo ownInfo, PeerInfo peerInfo, String privateKey,
      {PeerLocation? location}) async {
    final packetIntroduction = IntroductionMessage(
      'Hallo from ${ownInfo.name} here are my informations: ${ownInfo.peerID},${ownInfo.name},${ownInfo.selectedIp},${ownInfo.port},${ownInfo.publicKey}',
      requestReply: true,
    );
    await _peer.sendPacketToPeer(peerInfo, privateKey, packetIntroduction,
        location: location);
  }

  Future<void> syncWithAllKnownPeers(String privateKey) async {
    l.info('syncing task list with all known peers');

    final peers = await _peerInfoService.devices;
    await _peer.sendPacketToAllPeers(
        await _taskListsService.crdtToJson(), privateKey, true, peers);
    await _peer.sendPacketToAllPeers(
        await _taskListService.crdtToJson(), privateKey, false, peers);
  }
}
