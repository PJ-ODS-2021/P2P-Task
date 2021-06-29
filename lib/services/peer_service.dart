import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/network/messages/debug_message.dart';
import 'package:p2p_task/network/messages/task_list_message.dart';
import 'package:p2p_task/network/messages/introduction_message.dart';
import 'package:p2p_task/network/messages/task_lists_message.dart';
import 'package:p2p_task/network/peer/web_socket_client.dart';
import 'package:p2p_task/network/web_socket_peer.dart';
import 'package:p2p_task/services/change_callback_provider.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/network_info_service.dart';
import 'package:p2p_task/services/peer_info_service.dart';
import 'package:p2p_task/services/sync_service.dart';
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
  final NetworkInfoService _networkInfoService;
  final SyncService _syncService;
  final keyHelper = KeyHelper();

  PeerService(
    this._peer,
    this._taskListService,
    this._taskListsService,
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

    _syncService.startJob(syncWithAllKnownPeers);
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

    var publicKeyPem = values[4];

    var peerInfo = PeerInfo()
      ..id = values[0]
      ..name = values[1]
      ..locations.add(PeerLocation('ws://${values[2]}:${values[3]}'))
      ..publicKeyPem = publicKeyPem;

    await _peerInfoService.upsert(peerInfo);

    var peerID = await _identityService.peerId;
    var name = await _identityService.name;

    _peer.sendPacketTo(
      source,
      IntroductionMessage('Hello back from $name,$peerID'),
      keyHelper.decodePublicKeyFromPem(publicKeyPem),
    );
  }

  void _handleIntroductionReplyMessage(String encryptedMessage) async {
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
      if (taskListMessage.publicKeyPem == null) {
        l.severe('missing public key for request reply');

        return;
      }
      _peer.sendPacketTo(
        source,
        TaskListMessage(taskListCrdtJson),
        keyHelper.decodePublicKeyFromPem(taskListMessage.publicKeyPem!),
      );

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
      if (taskListsMessage.publicKeyPem == null) {
        l.severe('missing public key for request reply');

        return;
      }

      _peer.sendPacketTo(
        source,
        TaskListsMessage(taskListCrdtJson),
        keyHelper.decodePublicKeyFromPem(taskListsMessage.publicKeyPem!),
      );

      // TODO: propagate new task lists through the network using other connected and known peers (if updated)
    } else {
      l.info('Server received TaskListsMessage');
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
    final packetTasks = TaskListMessage(
      await _taskListService.crdtToJson(),
      requestReply: true,
      publicKeyPem: await _identityService.publicKeyPem,
    );
    final packetLists = TaskListsMessage(
      await _taskListsService.crdtToJson(),
      requestReply: true,
      publicKeyPem: await _identityService.publicKeyPem,
    );

    await _peer.sendPacketToPeer(
        peerInfo, await _identityService.privateKey, packetLists,
        location: location);
    await _peer.sendPacketToPeer(
        peerInfo, await _identityService.privateKey, packetTasks,
        location: location);
  }

  Future<void> sendIntroductionMessageToPeer(
    PeerInfo peerInfo, {
    PeerLocation? location,
  }) async {
    var peerID = await _identityService.peerId;
    var name = await _identityService.name;
    var ip = _selectIp(_networkInfoService.ips, await _identityService.ip);
    var port = await _identityService.port;
    var publicKey = await _identityService.publicKeyPem;

    final packetIntroduction = IntroductionMessage(
      'Hallo from $name here are my informations: $peerID,$name,$ip,$port,$publicKey',
      requestReply: true,
    );
    await _peer.sendPacketToPeer(
      peerInfo,
      await _identityService.privateKey,
      packetIntroduction,
      location: location,
    );
  }

  Future<void> syncWithAllKnownPeers() async {
    l.info('syncing task list with all known peers');
    final packetTasks = TaskListMessage(
      await _taskListService.crdtToJson(),
      requestReply: true,
      publicKeyPem: await _identityService.publicKeyPem,
    );
    final packetLists = TaskListsMessage(
      await _taskListsService.crdtToJson(),
      requestReply: true,
      publicKeyPem: await _identityService.publicKeyPem,
    );
    final peers = await _peerInfoService.devices;

    await _peer.sendPacketToAllPeers(
      packetLists,
      peers,
      await _identityService.privateKey,
    );

    await _peer.sendPacketToAllPeers(
      packetTasks,
      peers,
      await _identityService.privateKey,
    );
  }
}

// refactor -> qr_code_dioalog
String? _selectIp(List<String> ips, String? storedIp) {
  if (ips.contains(storedIp)) return storedIp;

  return ips.isNotEmpty ? ips.first : null;
}
