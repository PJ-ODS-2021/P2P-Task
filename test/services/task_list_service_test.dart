import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/models/task_list.dart';
import 'package:uuid/uuid.dart';

import '../utils/device_task_list.dart';
import '../utils/unordered_list_compare.dart';

void main() {
  late DeviceTaskList device;

  setUp(() async {
    device = await DeviceTaskList.create(name: 'device');
  });

  test('create task list', () async {
    final listId = Uuid().v4();
    final taskList = TaskList(id: listId, title: 'list1');
    await device.taskListService.upsertTaskList(taskList);
    final taskLists = (await device.taskListService.taskLists).toList();
    expect(taskLists.length, 1);
    expect(taskLists.first.id, listId);
    expect(taskLists.first.title, 'list1');
    expect(taskLists.first.elements, []);
  });

  test('create and remove task list', () async {
    final listId = Uuid().v4();
    final taskList = TaskList(id: listId, title: 'list1');
    await device.taskListService.upsertTaskList(taskList);
    await device.taskListService.removeTaskList(listId);
    expect((await device.taskListService.taskLists).toList(), []);
  });

  test('create and get task', () async {
    final task = Task(title: 'Catch a cat falling from the sky');
    await device.taskListService
        .upsertTaskList(TaskList(id: 'listId', title: 'list1'));
    await device.taskListService.upsertTask('listId', task);
    expect(task.id, isNot(null));
    expect((await device.taskListService.allTasks).toList(), [task]);
  });

  test('create and remove task', () async {
    final task = Task(title: 'Catch a cat falling from the sky');
    await device.taskListService
        .upsertTaskList(TaskList(id: 'listId', title: 'list1'));
    await device.taskListService.upsertTask('listId', task);
    await device.taskListService.removeTask('listId', task.id!);
    expect((await device.taskListService.allTasks).toList(), []);
  });

  test('create, remove and re-insert task', () async {
    final task1 = Task(title: 'Catch a cat falling from the sky');
    final task2 = Task(title: 'Drink a cold cat');
    await device.taskListService
        .upsertTaskList(TaskList(id: 'listId', title: 'list1'));
    await device.taskListService.upsertTask('listId', task1);
    await device.taskListService.removeTask('listId', task1.id!);
    await device.taskListService.upsertTask('listId', task2..id = task1.id);
    expect((await device.taskListService.allTasks).toList(), [task2]);
  });

  test('create task and remove its task list', () async {
    final task = Task(title: 'Catch a cat falling from the sky');
    await device.taskListService
        .upsertTaskList(TaskList(id: 'listId', title: 'list1'));
    await device.taskListService.upsertTask('listId', task);
    await device.taskListService.removeTaskList('listId');
    expect((await device.taskListService.allTasks).toList(), []);
  });

  test('should retrieve activities for created tasks', () async {
    final task1 = Task(title: 'Catch a cat falling from the sky');
    final task2 = Task(title: 'Drink a cold cat');
    await device.taskListService
        .upsertTaskList(TaskList(id: 'id1', title: 'list1'));
    await device.taskListService.upsertTask('id1', task1);
    await device.taskListService.upsertTask('id1', task2);

    final taskActivities =
        (await device.taskListService.taskActivities).toList();
    expect(
      unorderedListEquality(
        taskActivities.map((v) => v.task).toList(),
        {task1, task2},
      ),
      true,
    );
    taskActivities
        .forEach((taskRecord) => expect(taskRecord.taskListId, 'id1'));
  });

  test('should retrieve activities for deleted tasks', () async {
    final task1 = Task(title: 'Catch a cat falling from the sky');
    await device.taskListService
        .upsertTaskList(TaskList(id: 'id1', title: 'list1'));
    await device.taskListService.upsertTask('id1', task1);
    await device.taskListService.removeTask('id1', task1.id!);

    final allTaskRecords =
        (await device.taskListService.taskActivities).toList();
    expect(allTaskRecords.length, 1);
    expect(allTaskRecords.first.isDeleted, true);
  });

  tearDown(() async {
    await device.close();
  });
}
