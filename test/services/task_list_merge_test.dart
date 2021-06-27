import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/models/task_list.dart';
import '../utils/device_task_list.dart';

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
    await devices[0]
        .taskListService
        .upsertTaskList(TaskList(id: 'id1', title: 'list1'));
    await devices[0].taskListService.upsertTask('id1', task1);
    await devices[1]
        .taskListService
        .upsertTaskList(TaskList(id: 'id2', title: 'list2'));
    await devices[1].taskListService.upsertTask('id2', task2);

    expect(await devices[0].taskListService.allTasks, [task1]);
    expect(
      (await devices[0].taskListService.getTaskListById('id1'))?.elements,
      [task1],
    );
    expect(await devices[0].taskListService.getTasksFromList('id1'), [task1]);
    expect(await devices[1].taskListService.allTasks, [task2]);
    expect(
      (await devices[1].taskListService.getTaskListById('id2'))?.elements,
      [task2],
    );
    expect(await devices[1].taskListService.getTasksFromList('id2'), [task2]);
  });

  test('crdt merge tasks unordered same list', () async {
    final task1 = Task(title: 'task1');
    final task2 = Task(title: 'task2');
    await devices[0]
        .taskListService
        .upsertTaskList(TaskList(id: 'id', title: 'list'));
    await devices[0].taskListService.upsertTask('id', task1);
    await devices[1]
        .taskListService
        .upsertTaskList(TaskList(id: 'id', title: 'list'));
    await devices[1].taskListService.upsertTask('id', task2);

    await devices[0]
        .taskListService
        .mergeCrdtJson(await devices[1].taskListService.crdtToJson());

    final taskLists = (await devices[0].taskListService.taskLists).toList();
    expect(taskLists.length, 1);
    expect(taskLists.first.id, 'id');
    expect(taskLists.first.title, 'list');
    expect(taskLists.first.elements.toSet(), {task1, task2});
    expect(
      (await devices[0].taskListService.getTasksFromList('id')).toSet(),
      {task1, task2},
    );
    expect((await devices[0].taskListService.allTasks).toSet(), {task1, task2});
  });

  test('crdt merge clock drift', () async {
    // This test is highly dependent on the underlying crdt implementation.
    // The flutter crdt library throws a ClockDriftException when trying to merge with a Hlc timestamp that is more than 1 minute in the future.
    // The new implementation should not care.

    final taskList1 = TaskList(id: 'id1', title: 'taskList1');
    final taskList2 = TaskList(id: 'id2', title: 'taskList2');
    await devices[0].taskListService.upsertTaskList(taskList1);
    await devices[1].taskListService.upsertTaskList(taskList2);

    final Map<String, dynamic> device1Crdt =
        jsonDecode(await devices[1].taskListService.crdtToJson());
    final Map<String, dynamic> device1Tasks = device1Crdt['records'];
    expect(device1Tasks.length, 1);
    final Map<String, dynamic> device1Task1 = device1Tasks.values.first;
    expect(device1Task1.containsKey('clock'), true);
    expect(device1Task1['clock'].containsKey('timestamp'), true);
    device1Task1['clock']['timestamp'] =
        DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch;

    await devices[0].taskListService.mergeCrdtJson(jsonEncode(device1Crdt));
    expect(
      (await devices[0].taskListService.taskLists).toSet(),
      {taskList1, taskList2},
    );
  });

  test('crdt update less recent task in list', () async {
    final taskList = TaskList(id: 'id', title: 'list');
    final task1 = Task(id: 'task1id', title: 'task1');
    final task2 = Task(id: task1.id, title: 'task2');
    await devices[0].taskListService.upsertTaskList(taskList);
    await devices[0].taskListService.upsertTask(taskList.id!, task1);
    await Future.delayed(Duration(milliseconds: 10));
    await devices[1].taskListService.upsertTaskList(taskList);
    await devices[1].taskListService.upsertTask(taskList.id!, task2);

    await devices[0]
        .taskListService
        .mergeCrdtJson(await devices[1].taskListService.crdtToJson());
    final mergedTaskLists =
        (await devices[0].taskListService.taskLists).toList();
    expect(mergedTaskLists.length, 1);
    final mergedTaskList = mergedTaskLists.first;
    expect(mergedTaskList.title, taskList.title);
    expect(mergedTaskList.elements.toSet(), {task2});
  });

  test('crdt keep more recent task in list', () async {
    final taskList = TaskList(id: 'id', title: 'list');
    final task1 = Task(id: 'task1id', title: 'task1');
    final task2 = Task(id: task1.id, title: 'task2');
    await devices[1].taskListService.upsertTaskList(taskList);
    await devices[1].taskListService.upsertTask(taskList.id!, task2);
    await Future.delayed(Duration(milliseconds: 10));
    await devices[0].taskListService.upsertTaskList(taskList);
    await devices[0].taskListService.upsertTask(taskList.id!, task1);

    await devices[0]
        .taskListService
        .mergeCrdtJson(await devices[1].taskListService.crdtToJson());
    final mergedTaskLists =
        (await devices[0].taskListService.taskLists).toList();
    expect(mergedTaskLists.length, 1);
    final mergedTaskList = mergedTaskLists.first;
    expect(mergedTaskList.title, taskList.title);
    expect(mergedTaskList.elements.toSet(), {task1});
  });

  test('crdt recursive task merge in list', () async {
    final taskList = TaskList(id: 'id', title: 'list');
    final task1 = Task(
      id: 'task1Id',
      title: 'task1',
      description: 'description1',
    );
    final task2 = Task(
      id: task1.id,
      title: 'task2',
      description: 'description2',
    );
    await devices[0].taskListService.upsertTaskList(taskList);
    await devices[0].taskListService.upsertTask(taskList.id!, task1);
    await devices[1].taskListService.upsertTaskList(taskList);
    await devices[1].taskListService.upsertTask(taskList.id!, task2);

    // two-way merge:
    await devices[0]
        .taskListService
        .mergeCrdtJson(await devices[1].taskListService.crdtToJson());
    await devices[1]
        .taskListService
        .mergeCrdtJson(await devices[0].taskListService.crdtToJson());

    // update title in device 1 and description in device 2:
    await devices[0]
        .taskListService
        .upsertTask(taskList.id!, task1..title = 'task1 updated');
    await devices[1]
        .taskListService
        .upsertTask(taskList.id!, task2..description = 'task2 description');

    await devices[0]
        .taskListService
        .mergeCrdtJson(await devices[1].taskListService.crdtToJson());
    expect((await devices[0].taskListService.allTasks).toSet(), {
      Task(
        id: task2.id,
        title: 'task1 updated',
        description: 'task2 description',
      ),
    });
  });

  tearDown(() async {
    await Future.wait(devices.map((device) => device.close()));
  });
}