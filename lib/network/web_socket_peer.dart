import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/network/packet.dart';
import 'package:p2p_task/network/packet_handler.dart';
import 'package:p2p_task/network/peer/web_socket_client.dart';
import 'package:p2p_task/network/peer/web_socket_server.dart';
import 'package:p2p_task/network/serializable.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/peer_info_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/utils/log_mixin.dart';

import 'messages/debug_message.dart';
import 'messages/task_list_message.dart';

class WebSocketPeer extends ChangeNotifier with LogMixin, PacketHandler {
  WebSocketServer _webSocketServer;
  WebSocketClient _webSocketClient;
  TaskListService _taskListService;
  PeerInfoService _peerInfoService;
  IdentityService _identityService;
  SyncService _syncService;

  int get port => _webSocketServer.port;
  String get address => _webSocketServer.address;
  bool get isServerRunning => _webSocketServer.isRunning;

  WebSocketPeer(
      WebSocketServer webSocketServer,
      WebSocketClient webSocketClient,
      TaskListService taskListService,
      PeerInfoService peerInfoService,
      IdentityService identityService,
      SyncService syncService)
      : this._webSocketServer = webSocketServer,
        this._webSocketClient = webSocketClient,
        this._taskListService = taskListService,
        this._peerInfoService = peerInfoService,
        this._identityService = identityService,
        this._syncService = syncService {
    _registerTypes();
    if (!kIsWeb) start();
    _syncService.startJob(syncWithKnownPeers);
  }

  Future start() async {
    l.info('Starting initialization of Peer...');
    await _webSocketServer.start(await _identityService.port,
        onData: (channel, data) async {
      l.info('Received message from connected peer: $data');
      _handleMessage(data);
    });
    notifyListeners();
  }

  Future syncWithKnownPeers() async {
    final peers = await _peerInfoService.devices;
    peers.forEach(sync);
  }

  Future sync(PeerInfo peer) async {
    l.info('Starting sync with ${peer.id} on ${peer.ip}:${peer.port}...');
    _webSocketClient.connect(peer.ip, peer.port);
    _webSocketClient.dataStream.listen(
      (data) async {
        l.info('Received message from server: $data');
        _handleMessage(data);
      },
      onError: (error, stackTrace) => l.info('Error', error, stackTrace),
    );
    final payload = TaskListMessage(await _taskListService.crdtToJson(),
        requestReply: true);
    l.info('Client sent message with ${payload.toJson()}');
    _send(_marshall(payload));
  }

  Future stopServer() async {
    await _webSocketServer.close();
    notifyListeners();
  }

  Future _handleMessage(String message) async {
    final unmarshalledData = _unmarshal(message);
    if (unmarshalledData is DebugMessage)
      print('Received DebugMessage: ${unmarshalledData.value}');
    else if (unmarshalledData is TaskListMessage)
      await _mergeCallback(unmarshalledData);
  }

  Future _mergeCallback(TaskListMessage taskListMessage) async {
    l.info('Received TaskListMessage');
    await _taskListService.mergeCrdtJson(taskListMessage.taskListCrdtJson);
    if (taskListMessage.requestReply) {
      final payload =
          _marshall(TaskListMessage(await _taskListService.crdtToJson()));
      _send(payload);
      l.info('Server received TaskListMessage and sent $payload to client');
    } else {
      l.info('Server received TaskListMessage');
    }
  }

  String _marshall<T extends Serializable>(T payload) {
    return jsonEncode(toPacket(payload).toJson());
  }

  Serializable _unmarshal(String message) {
    final decodedMessage = Packet.fromJson(jsonDecode(message));
    switch (decodedMessage.typename) {
      case 'DebugMessage':
        return DebugMessage.fromJson(decodedMessage.object);
      case 'TaskListMessage':
        return TaskListMessage.fromJson(decodedMessage.object);
      default:
        return DebugMessage('Unknown typename.');
    }
  }

  _send(String payload) {
    _webSocketServer.sendToClients(payload);
    _webSocketClient.send(payload);
  }

  void _registerTypes() {
    registerTypename<DebugMessage>(
        "DebugMessage", (json) => DebugMessage.fromJson(json));
    registerTypename<TaskListMessage>(
        "TaskListMessage", (json) => TaskListMessage.fromJson(json));
  }

  Future dispose() async {
    await _webSocketServer.close();
    await _webSocketClient.close();
    super.dispose();
  }
}
