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
            (await devices[1].taskList.taskListService.taskLists).toList();
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
          (await devices[1].taskList.taskListService.taskLists).toList(),
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
          await devices[1].peerInfoService.upsert(device0PeerInfo);

          {
            // expect unreachable peer info to be in first location
            final peerInfos = await devices[1].peerInfoService.devices;
            expect(peerInfos.length, 1);
            expect(
              peerInfos.first.locations,
              [unreachablePeerLocation, reachablePeerInfo],
            );
          }
          await devices[1].peerService.syncWithAllKnownPeers();
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
    });

    tearDown(() async {
      await Future.wait(devices.map((device) => device.close()));
    });
  });
}
