import 'dart:convert';

import 'package:crdt/crdt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';

class DeviceTaskList {
  final Database database;
  final KeyValueRepository keyValueRepository;
  final IdentityService identityService;
  final SyncService syncService;
  final TaskListService taskListService;

  DeviceTaskList(this.database, this.keyValueRepository, this.identityService,
      this.syncService, this.taskListService);

  static Future<DeviceTaskList> create(
      {DatabaseFactory? databaseFactory,
      String? databasePath,
      String? name}) async {
    final database = await (databaseFactory ?? newDatabaseFactoryMemory())
        .openDatabase(databasePath ?? sembastInMemoryDatabasePath);
    final keyValueRepository = KeyValueRepository(database);
    final identityService = IdentityService(keyValueRepository);
    if (name != null) await identityService.setName(name);
    final syncService = SyncService(keyValueRepository);
    final taskListService =
        TaskListService(keyValueRepository, identityService, syncService);
    return DeviceTaskList(database, keyValueRepository, identityService,
        syncService, taskListService);
  }

  Future<void> close() {
    return database.close();
  }
}

void main() {
  var devices = <DeviceTaskList>[];

  setUp(() async {
    devices = [
      await DeviceTaskList.create(name: 'device1'),
      await DeviceTaskList.create(name: 'device2'),
    ];
  });

  test('distinct task lists', () async {
    final task1 = Task(title: 'task1');
    final task2 = Task(title: 'task2');
    await devices[0].taskListService.upsert(task1);
    await devices[1].taskListService.upsert(task2);

    expect(await devices[0].taskListService.tasks, [task1]);
    expect(await devices[1].taskListService.tasks, [task2]);
  });

  test('crdt merge tasks unordered', () async {
    final task1 = Task(title: 'task1');
    final task2 = Task(title: 'task2');
    await devices[0].taskListService.upsert(task1);
    await devices[1].taskListService.upsert(task2);

    await devices[0]
        .taskListService
        .mergeCrdtJson(await devices[1].taskListService.crdtToJson());
    expect(await devices[1].taskListService.tasks, [task2]);
    expect((await devices[0].taskListService.tasks).toSet(),
        [task1, task2].toSet());
  });

  test('crdt merge clock drift', () async {
    // The crdt library throws a ClockDriftException when trying to merge with a Hlc timestamp that is more than 1 minute in the future.

    final task1 = Task(title: 'task1');
    final task2 = Task(title: 'task2');
    await devices[0].taskListService.upsert(task1);
    await devices[1].taskListService.upsert(task2);

    final Map<String, dynamic> device1Tasks =
        jsonDecode(await devices[1].taskListService.crdtToJson());
    expect(device1Tasks.length, 1);
    final Map<String, dynamic> deviceTask1 = device1Tasks.values.first;
    expect(deviceTask1.containsKey('hlc'), true);
    deviceTask1['hlc'] = Hlc.fromDate(
            DateTime.now().add(Duration(minutes: 10)), device1Tasks.keys.first)
        .toJson();

    await devices[0].taskListService.mergeCrdtJson(jsonEncode(device1Tasks));
    expect(await devices[1].taskListService.tasks, [task2]);
    expect((await devices[0].taskListService.tasks).toSet(),
        [task1, task2].toSet());
  });

  tearDown(() async {
    await Future.wait(devices.map((device) => device.close()));
  });
}
