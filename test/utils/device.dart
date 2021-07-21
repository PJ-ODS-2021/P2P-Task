import 'dart:collection';

import 'package:mockito/mockito.dart';
import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/network/web_socket_peer.dart';
import 'package:p2p_task/services/network_info_service.dart';
import 'package:p2p_task/services/peer_info_service.dart';
import 'package:p2p_task/services/peer_service.dart';
import 'package:p2p_task/utils/data_model_repository.dart';

import 'device_task_list.dart';

class _FakeNetworkInfoService extends Fake implements NetworkInfoService {
  @override
  UnmodifiableListView<String> get ips => UnmodifiableListView(['127.0.0.1']);
}

class Device {
  final DeviceTaskList taskList;
  final PeerInfoService peerInfoService;
  final PeerService peerService;

  Device(
    this.taskList,
    this.peerInfoService,
    this.peerService,
  );

  static Future<Device> create({
    String? name,
    int? port,
    String? privateKey,
    String? publicKey,
  }) async {
    final taskList = await DeviceTaskList.create(name: name);
    if (port != null) await taskList.identityService.setPort(port);
    final peerInfoService = PeerInfoService(
      DataModelRepository(
        taskList.database,
        (json) => PeerInfo.fromJson(json),
        'PeerInfo',
      ),
      null,
    );

    final peerService = PeerService(
      WebSocketPeer(),
      taskList.taskListService,
      peerInfoService,
      taskList.identityService,
      _FakeNetworkInfoService(),
      null,
    );

    return Device(taskList, peerInfoService, peerService);
  }

  Future<PeerInfo> generatePeerInfo() async {
    return PeerInfo(
      id: await taskList.identityService.peerId,
      name: await taskList.identityService.name,
      status: Status.active,
      publicKeyPem: await taskList.identityService.publicKeyPem,
      locations: [
        PeerLocation('ws://localhost:${await taskList.identityService.port}'),
      ],
    );
  }

  Future<void> close() async {
    await peerService.stopServer();
    await taskList.close();
  }
}
