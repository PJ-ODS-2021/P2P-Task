import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/models/task_list.dart';
import 'package:p2p_task/network/web_socket_peer.dart';
import 'package:p2p_task/services/network_info_service.dart';
import 'package:p2p_task/services/peer_info_service.dart';
import 'package:p2p_task/services/peer_service.dart';
import 'package:p2p_task/utils/data_model_repository.dart';
import '../utils/device_task_list.dart';

class FakeNetworkInfoService extends Fake implements NetworkInfoService {
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
      FakeNetworkInfoService(),
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

void main() {
  late List<Device> devices;

  setUp(() async {
    devices = [
      await Device.create(name: 'device1', port: 58240),
      await Device.create(name: 'device2', port: 58242),
    ];
    await Future.wait(devices.map(
      (device) => device.peerService.startServer(),
    ));
  });

  group('Introduction message', () {
    test('should add new peer info on the receiving device', () async {
      final peerInfoDevice0 = await devices[0].generatePeerInfo();
      final peerInfoDevice1 = await devices[1].generatePeerInfo();
      final currentPeerInfo =
          await devices[1].peerInfoService.getByID(peerInfoDevice0.id!);
      expect(currentPeerInfo, equals(null));

      await devices[0].peerService.sendIntroductionMessageToPeer(
            peerInfoDevice1,
            location: peerInfoDevice1.locations.first,
          );

      final newPeerInfo =
          await devices[1].peerInfoService.getByID(peerInfoDevice0.id!);
      expect(newPeerInfo, isNot(null));
      expect(newPeerInfo!.name, equals(peerInfoDevice0.name));
      expect(newPeerInfo.publicKeyPem, equals(peerInfoDevice0.publicKeyPem));
    });
  });

  group('Delete peer message', () {
    test('should delete peer info on the receiving device', () async {
      final sendingDevice = devices[0];
      final receivingDevice = devices[1];

      await receivingDevice.peerInfoService
          .upsert(await devices[0].generatePeerInfo());

      expect(
        await receivingDevice.peerInfoService
            .getByID((await sendingDevice.generatePeerInfo()).id!),
        isNot(null),
      );

      await sendingDevice.peerService.sendDeletePeerMessageToPeer(
        await receivingDevice.generatePeerInfo(),
      );

      expect(
        await receivingDevice.peerInfoService
            .getByID((await sendingDevice.generatePeerInfo()).id!),
        equals(null),
      );
    });
  });

  group('Synchronization', () {
    test('should sync tasks with connecting client', () async {
      final taskList = TaskList(id: 'list1Id', title: 'list1');
      final task = Task(id: 'task1Id', title: 'Eat a hot dog');

      await devices[1]
          .peerInfoService
          .upsert(await devices[0].generatePeerInfo());

      await devices[0].taskList.taskListService.upsertTaskList(taskList);
      await devices[0].taskList.taskListService.upsertTask(taskList.id!, task);
      await devices[0]
          .peerInfoService
          .upsert(await devices[1].generatePeerInfo());
      await devices[0].peerService.syncWithAllKnownPeers();

      final device2TaskLists =
          (await devices[1].taskList.taskListService.taskLists).toList();
      expect(device2TaskLists.length, 1);
      expect(device2TaskLists.first.title, taskList.title);
      expect(device2TaskLists.first.elements, [task]);
    });
  });

  tearDown(() async {
    await Future.wait(devices.map((device) => device.close()));
  });
}
