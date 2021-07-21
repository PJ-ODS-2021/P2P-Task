import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/models/task_list.dart';

import '../utils/device.dart';

void main() {
  group('#PeerService', () {
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
            await devices[1].peerInfoService.getById(peerInfoDevice0.id!);
        expect(currentPeerInfo, equals(null));

        await devices[0]
            .peerService
            .sendIntroductionMessageToPeer(peerInfoDevice1);

        final newPeerInfo =
            await devices[1].peerInfoService.getById(peerInfoDevice0.id!);
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
              .getById((await sendingDevice.generatePeerInfo()).id!),
          isNot(null),
        );

        await sendingDevice.peerService.sendDeletePeerMessageToPeer(
          await receivingDevice.generatePeerInfo(),
        );

        expect(
          await receivingDevice.peerInfoService
              .getById((await sendingDevice.generatePeerInfo()).id!),
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
        await devices[0]
            .taskList
            .taskListService
            .upsertTask(taskList.id!, task);
        await devices[0]
            .peerInfoService
            .upsert(await devices[1].generatePeerInfo());
        await devices[0].peerService.syncWithAllKnownPeers();

        final device2TaskLists =
            (await devices[1].taskList.taskListService.getTaskLists()).toList();
        expect(device2TaskLists.length, 1);
        expect(device2TaskLists.first.title, taskList.title);
        expect(device2TaskLists.first.elements, [task]);
      });

      test('should try multiple peer locations', () async {
        final taskList = TaskList(id: 'list1Id', title: 'list1');
        final device0PeerInfo = await devices[0].generatePeerInfo();
        expect(device0PeerInfo.locations.length, 1);
        final unreachablePeerLocation = PeerLocation(
          device0PeerInfo.locations.first.uri.replace(port: 42).toString(),
        );

        device0PeerInfo.locations.insert(0, unreachablePeerLocation);
        await devices[1].peerInfoService.upsert(device0PeerInfo);
        await devices[1].taskList.taskListService.upsertTaskList(taskList);
        await devices[1].peerService.syncWithAllKnownPeers();

        expect(
          (await devices[1].taskList.taskListService.getTaskLists()).toList(),
          [taskList],
        );
      });

      test(
        'should should move connection location to front of peer location list',
        () async {
          final device0PeerInfo = await devices[0].generatePeerInfo();
          expect(device0PeerInfo.locations.length, 1);
          final reachablePeerInfo = device0PeerInfo.locations.first;
          final unreachablePeerLocation = PeerLocation(
            device0PeerInfo.locations.first.uri.replace(port: 42).toString(),
          );

          device0PeerInfo.locations.insert(0, unreachablePeerLocation);
          await devices[1]
              .peerInfoService
              .update(device0PeerInfo.id, (_) => device0PeerInfo);

          {
            // expect unreachable peer info to be in first location
            final peerInfos = await devices[1].peerInfoService.devices;
            expect(peerInfos.length, 1);
            expect(
              peerInfos.first.locations,
              [unreachablePeerLocation, reachablePeerInfo],
            );
          }
          await devices[1]
              .peerService
              .sendIntroductionMessageToPeer(device0PeerInfo);
          {
            // expect reachable peer info to be in first location
            final peerInfos = await devices[1].peerInfoService.devices;
            expect(peerInfos.length, 1);
            expect(
              peerInfos.first.locations,
              [reachablePeerInfo, unreachablePeerLocation],
            );
          }
        },
      );

      test('should respect peers that have changed their location', () async {
        final taskList = TaskList(id: 'list1Id', title: 'list1');

        devices.add(await Device.create(name: 'device3', port: 58250));
        await devices.last.peerService.startServer();

        final device0PeerInfo = await devices[0].generatePeerInfo();
        var device1PeerInfo = await devices[1].generatePeerInfo();
        var device2PeerInfo = await devices[2].generatePeerInfo();

        expect(
          device1PeerInfo.publicKeyPem,
          isNot(device2PeerInfo.publicKeyPem),
        );

        // add peer infos
        await devices[0].peerInfoService.upsert(device1PeerInfo);
        await devices[0].peerInfoService.upsert(device2PeerInfo);
        await devices[1].peerInfoService.upsert(device0PeerInfo);
        await devices[2].peerInfoService.upsert(device0PeerInfo);

        // switch device 1 and device 2 ports
        await devices[1].peerService.stopServer();
        await devices[2].peerService.stopServer();
        await devices[1]
            .taskList
            .identityService
            .setPort(device2PeerInfo.locations.first.uri.port);
        await devices[2]
            .taskList
            .identityService
            .setPort(device1PeerInfo.locations.first.uri.port);
        await devices[1].peerService.startServer();
        await devices[2].peerService.startServer();

        // add a task list in device 0
        await devices[0].taskList.taskListService.upsertTaskList(taskList);

        // sync form device 0 should do nothing because encryption keys are wrong
        await devices[0].peerService.syncWithAllKnownPeers();
        expect(
          (await devices[1].taskList.taskListService.getTaskLists()).isEmpty,
          true,
        );
        expect(
          (await devices[2].taskList.taskListService.getTaskLists()).isEmpty,
          true,
        );

        // sync from device 1 should work
        await devices[1].peerService.syncWithAllKnownPeers();
        expect(
          (await devices[1].taskList.taskListService.getTaskLists()).toList(),
          [taskList],
        );

        // sync from device 2 should work
        await devices[2].peerService.syncWithAllKnownPeers();
        expect(
          (await devices[2].taskList.taskListService.getTaskLists()).toList(),
          [taskList],
        );

        // remove the task list from device 0
        await devices[0].taskList.taskListService.removeTaskList(taskList.id!);

        // add new peer locations to end of peer location list
        device1PeerInfo = await devices[1].generatePeerInfo();
        device2PeerInfo = await devices[2].generatePeerInfo();
        await devices[0].peerInfoService.update(
              device1PeerInfo.id,
              (peerInfo) =>
                  peerInfo?..locations.addAll(device1PeerInfo.locations),
            );
        await devices[0].peerInfoService.update(
              device2PeerInfo.id,
              (peerInfo) =>
                  peerInfo?..locations.addAll(device2PeerInfo.locations),
            );

        // sync form device 0 should work
        await devices[0].peerService.syncWithAllKnownPeers();
        expect(
          (await devices[1].taskList.taskListService.getTaskLists()).isEmpty,
          true,
        );
        expect(
          (await devices[2].taskList.taskListService.getTaskLists()).isEmpty,
          true,
        );
      });
    });

    tearDown(() async {
      await Future.wait(devices.map((device) => device.close()));
    });
  });
}
