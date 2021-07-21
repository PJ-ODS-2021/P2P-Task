import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/models/task_list.dart';
import '../utils/device_task_list.dart';
import '../utils/unordered_list_compare.dart';

void main() {
  var devices = <DeviceTaskList>[];

  setUp(() async {
    devices = [
      await DeviceTaskList.create(name: 'device1'),
      await DeviceTaskList.create(name: 'device2'),
    ];
  });

  test('crdt onw-way-merge tasks unordered same list', () async {
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

    final taskLists =
        (await devices[0].taskListService.getTaskLists()).toList();
    expect(taskLists.length, 1);
    expect(taskLists.first.id, 'id');
    expect(taskLists.first.title, 'list');
    expect(
      unorderedListEquality(
        taskLists.first.elements,
        {task1, task2},
      ),
      true,
    );
  });

  test('crdt one-way-merge clock drift', () async {
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
      unorderedListEquality(
        (await devices[0].taskListService.getTaskLists(decodeTasks: false))
            .toList(),
        {taskList1, taskList2},
      ),
      true,
    );
  });

  test('crdt one-way-merge update less recent task in list', () async {
    // TODO: use fake time

    final taskList = TaskList(id: 'listId', title: 'list');
    final task1 = Task(id: 'task1id', title: 'task1');
    final task2 = Task(id: 'task1id', title: 'task2');
    await devices[0].taskListService.upsertTaskList(taskList);
    await devices[0].taskListService.upsertTask('listId', task1);
    await Future.delayed(Duration(milliseconds: 1));
    await devices[1].taskListService.upsertTaskList(taskList);
    await devices[1].taskListService.upsertTask('listId', task2);

    await devices[0]
        .taskListService
        .mergeCrdtJson(await devices[1].taskListService.crdtToJson());
    final mergedTaskLists =
        (await devices[0].taskListService.getTaskLists()).toList();
    expect(mergedTaskLists.length, 1);
    final mergedTaskList = mergedTaskLists.first;
    expect(mergedTaskList.title, taskList.title);
    expect(
      unorderedListEquality(mergedTaskList.elements.toList(), {task2}),
      true,
    );
  });

  test('crdt one-way-merge keep more recent task in list', () async {
    // TODO: use fake time

    final taskList = TaskList(id: 'listId', title: 'list');
    final task1 = Task(id: 'task1id', title: 'task1');
    final task2 = Task(id: 'task1id', title: 'task2');
    await devices[1].taskListService.upsertTaskList(taskList);
    await devices[1].taskListService.upsertTask('listId', task2);
    await Future.delayed(Duration(milliseconds: 1));
    await devices[0].taskListService.upsertTaskList(taskList);
    await devices[0].taskListService.upsertTask('listId', task1);

    await devices[0]
        .taskListService
        .mergeCrdtJson(await devices[1].taskListService.crdtToJson());
    final mergedTaskLists =
        (await devices[0].taskListService.getTaskLists()).toList();
    expect(mergedTaskLists.length, 1);
    final mergedTaskList = mergedTaskLists.first;
    expect(mergedTaskList.title, taskList.title);
    expect(
      unorderedListEquality(mergedTaskList.elements.toList(), {task1}),
      true,
    );
  });

  test('crdt two-way-merge recursive task in list', () async {
    final taskList = TaskList(id: 'listId', title: 'list');
    final task1 = Task(
      id: 'task1Id',
      title: 'task1',
      description: 'description1',
    );
    final task2 = Task(
      id: 'task1Id',
      title: 'task2',
      description: 'description2',
    );
    await devices[0].taskListService.upsertTaskList(taskList);
    await devices[0].taskListService.upsertTask('listId', task1);
    await devices[1].taskListService.upsertTaskList(taskList);
    await devices[1].taskListService.upsertTask('listId', task2);

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
        .upsertTask('listId', task1..title = 'task1 updated');
    await devices[1]
        .taskListService
        .upsertTask('listId', task2..description = 'task2 description');

    await devices[0]
        .taskListService
        .mergeCrdtJson(await devices[1].taskListService.crdtToJson());
    final taskLists =
        (await devices[0].taskListService.getTaskLists()).toList();
    expect(taskLists.length, 1);
    expect(taskLists.first.elements.length, 1);
    expect(taskLists.first.elements.first.id, 'task1Id');
    expect(taskLists.first.elements.first.title, 'task1 updated');
    expect(taskLists.first.elements.first.description, 'task2 description');
  });

  test(
    'crdt two-way-merge recursive task in list with out-of-sync clocks',
    () async {
      final taskList = TaskList(id: 'listId', title: 'list');
      final task = Task(title: 'task1', completed: false, isFlagged: false);
      await devices[0].taskListService.upsertTaskList(taskList);
      await devices[0].taskListService.upsertTask('listId', task);

      // two-way merge
      await devices[0]
          .taskListService
          .mergeCrdtJson(await devices[1].taskListService.crdtToJson());
      await devices[1]
          .taskListService
          .mergeCrdtJson(await devices[0].taskListService.crdtToJson());

      final setTaskPropertyTimestamp = (
        Map<String, dynamic> crdt,
        String taskListId,
        String taskId,
        int timestamp, {
        String? property,
      }) async {
        final taskCrdt = crdt['records'][taskListId]['value'][taskId];
        final clock = property != null
            ? taskCrdt['value'][property]['clock']
            : taskCrdt['clock'];
        clock['timestamp'] = timestamp;
      };

      // mark as completed in device 0 and backdate timestamp
      await devices[0].taskListService.upsertTask(
            'listId',
            Task(
              id: task.id,
              title: task.title,
              completed: true,
              isFlagged: task.isFlagged,
            ),
          );
      final device0Crdt =
          jsonDecode(await devices[0].taskListService.crdtToJson());
      await setTaskPropertyTimestamp(
        device0Crdt,
        'listId',
        task.id!,
        0,
        property: 'completed',
      );

      // mark flagged in device 1
      await devices[1].taskListService.upsertTask(
            'listId',
            Task(
              id: task.id,
              title: task.title,
              completed: task.completed,
              isFlagged: true,
            ),
          );

      await devices[1].taskListService.mergeCrdtJson(jsonEncode(device0Crdt));
      final expectedTask = Task(
        id: task.id,
        title: task.title,
        completed: true,
        isFlagged: true,
      );

      // completed and flagged should be marked as true
      final taskLists =
          (await devices[1].taskListService.getTaskLists()).toList();
      expect(taskLists.length, 1);
      expect(
        unorderedListEquality(taskLists.first.elements, {expectedTask}),
        true,
      );
    },
  );

  tearDown(() async {
    await Future.wait(devices.map((device) => device.close()));
  });
}
