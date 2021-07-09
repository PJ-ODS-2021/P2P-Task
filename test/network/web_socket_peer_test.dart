import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/models/task_list.dart';
import 'package:p2p_task/network/web_socket_peer.dart';
import 'package:p2p_task/services/peer_info_service.dart';
import 'package:p2p_task/services/peer_service.dart';
import 'package:p2p_task/utils/data_model_repository.dart';
import '../utils/device_task_list.dart';

class Device {
  final DeviceTaskList taskList;
  final PeerInfoService peerInfoService;
  final PeerService peerService;

  Device(this.taskList, this.peerInfoService, this.peerService);

  static Future<Device> create({String? name, int? port}) async {
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
      null,
    );

    return Device(taskList, peerInfoService, peerService);
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
      await Device.create(name: 'device2', port: 58241),
    ];
    await Future.wait(devices.map(
      (device) => device.peerService.startServer(),
    ));
  });

  group('Synchronization', () {
    test('should sync tasks with connecting client', () async {
      final taskList = TaskList(id: 'list1Id', title: 'list1');
      final task = Task(id: 'task1Id', title: 'Eat a hot dog');

      await devices[0].taskList.taskListService.upsertTaskList(taskList);
      await devices[0].taskList.taskListService.upsertTask(taskList.id!, task);
      final device1Port = await devices[1].taskList.identityService.port;
      await devices[0].peerInfoService.upsert(PeerInfo()
        ..locations.add(PeerLocation('ws://localhost:$device1Port')));
      await devices[0].peerService.syncWithAllKnownPeers();

      final device2TaskLists =
          (await devices[1].taskList.taskListService.getTaskLists()).toList();
      expect(device2TaskLists.length, 1);
      expect(device2TaskLists.first.title, taskList.title);
      expect(device2TaskLists.first.elements, [task]);
    });
  });

  tearDown(() async {
    await Future.wait(devices.map((device) => device.close()));
  });
}
