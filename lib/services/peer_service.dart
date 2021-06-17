import 'package:flutter/widgets.dart';
import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/network/messages/debug_message.dart';
import 'package:p2p_task/network/messages/task_list_message.dart';
import 'package:p2p_task/network/peer/web_socket_client.dart';
import 'package:p2p_task/network/web_socket_peer.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/peer_info_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/utils/log_mixin.dart';

class PeerService extends ChangeNotifier with LogMixin {
  WebSocketPeer _peer;
  TaskListService _taskListService;
  PeerInfoService _peerInfoService;
  IdentityService _identityService;
  SyncService _syncService;

  PeerService(this._peer, this._taskListService, this._peerInfoService,
      this._identityService, this._syncService) {
    _peer.clear();

    _peer.registerTypename<DebugMessage>(
        "DebugMessage", (json) => DebugMessage.fromJson(json));
    _peer.registerTypename<TaskListMessage>(
        "TaskListMessage", (json) => TaskListMessage.fromJson(json));
    _peer.registerCallback<DebugMessage>(_debugMessageCallback);
    _peer.registerCallback<TaskListMessage>(_taskListMessageCallback);

    _syncService.startJob(syncWithAllKnownPeers);
  }

  bool get isServerRunning => _peer.isServerRunning;
  String? get serverAddress => _peer.serverAddress;
  int? get serverPort => _peer.serverPort;

  void _debugMessageCallback(
      DebugMessage debugMessage, WebSocketClient source) {
    l.info('Received debug message: ${debugMessage.value}');
  }

  Future<void> _taskListMessageCallback(
      TaskListMessage taskListMessage, WebSocketClient source) async {
    l.info('Received TaskListMessage');
    await _taskListService.mergeCrdtJson(taskListMessage.taskListCrdtJson);
    if (taskListMessage.requestReply) {
      final taskListCrdtJson = await _taskListService.crdtToJson();
      _peer.sendPacketTo(source, TaskListMessage(taskListCrdtJson));

      // TODO: propagate new task list through the network using other connected and known peers (if updated)
    } else {
      l.info('Server received TaskListMessage');
    }
  }

  Future<void> startServer() async {
    final port = await _identityService.port;
    await _peer.startServer(port);
    notifyListeners();
  }

  Future<void> stopServer() async {
    await _peer.stopServer();
    notifyListeners();
  }

  Future<void> syncWithPeer(PeerInfo peerInfo, {PeerLocation? location}) async {
    final packet = TaskListMessage(await _taskListService.crdtToJson(),
        requestReply: true);
    await _peer.sendPacketToPeer(peerInfo, packet, location: location);
  }

  Future<void> syncWithAllKnownPeers() async {
    l.info('syncing task list with all known peers');
    final packet = TaskListMessage(await _taskListService.crdtToJson(),
        requestReply: true);
    final peers = await _peerInfoService.devices;
    await _peer.sendPacketToAllPeers(packet, peers);
  }
}
