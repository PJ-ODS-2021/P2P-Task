import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/models/task_list.dart';
import 'package:p2p_task/services/activity_record.dart';
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

  group('activities', () {
    test('for created tasks', () async {
      final task1 = Task(title: 'Catch a cat falling from the sky');
      final task2 = Task(title: 'Drink a cold cat');
      await device.taskListService
          .upsertTaskList(TaskList(id: 'listId', title: 'list1'));
      await device.taskListService.upsertTask('listId', task1);
      await device.taskListService.upsertTask('listId', task2);

      final taskActivities =
          (await device.taskListService.taskActivities).toList();
      final tasks = taskActivities.map((v) => v.task).toList();
      expect(
        unorderedListEquality(tasks, {task1, task2}),
        true,
        reason: 'got ${tasks.map((e) => e?.toJson())}, expected ${{
          task1,
          task2,
        }.map((e) => e.toJson())}',
      );
      taskActivities
          .forEach((taskRecord) => expect(taskRecord.taskListId, 'listId'));
    });

    test('for deleted tasks', () async {
      final task1 = Task(title: 'Catch a cat falling from the sky');
      await device.taskListService
          .upsertTaskList(TaskList(id: 'listId', title: 'list1'));
      await device.taskListService.upsertTask('listId', task1);
      await device.taskListService.removeTask('listId', task1.id!);

      final taskActivities =
          (await device.taskListService.taskActivities).toList();
      expect(taskActivities.length, 1);
      expect(taskActivities.first.isDeleted, true);
      expect(taskActivities.first.taskListId, 'listId');
    });

    test('for updated tasks', () async {
      final task =
          Task(title: 'Catch a cat falling from the sky', description: '');
      await device.taskListService
          .upsertTaskList(TaskList(id: 'listId', title: 'list1'));
      await device.taskListService.upsertTask('listId', task);
      await device.taskListService
          .upsertTask('listId', task..description = 'a new description');

      final taskActivities =
          (await device.taskListService.taskActivities).toList();
      expect(taskActivities.length, 2);
      taskActivities.forEach((activity) {
        expect(activity.task, task);
        expect(activity.taskListId, 'listId');
      });
      expect(
        taskActivities.where((activity) => activity.isRecursiveUpdate).length,
        1,
      );
    });

    test('for multiple updates in one task', () async {
      final task = Task(
        title: 'Catch a cat falling from the sky',
        description: '',
        completed: false,
      );
      await device.taskListService
          .upsertTaskList(TaskList(id: 'listId', title: 'list1'));
      await device.taskListService.upsertTask('listId', task);
      await device.taskListService
          .upsertTask('listId', task..description = 'a new description');
      await device.taskListService.upsertTask('listId', task..completed = true);

      final taskActivities =
          (await device.taskListService.taskActivities).toList();
      expect(taskActivities.length, 3);
      taskActivities.forEach((activity) {
        expect(activity.task, task);
        expect(activity.taskListId, 'listId');
      });
      expect(
        taskActivities.where((activity) => activity.isRecursiveUpdate).length,
        2,
      );
    });

    test('for created task lists', () async {
      final list1 = TaskList(id: 'listId1', title: 'list1');
      final list2 = TaskList(id: 'listId2', title: 'list2');
      await device.taskListService.upsertTaskList(list1);
      await device.taskListService.upsertTaskList(list2);

      final listActivities =
          (await device.taskListService.taskListActivities).toList();
      final lists = listActivities.map((v) => v.taskList).toList();
      expect(
        unorderedListEquality(lists, {list1, list2}),
        true,
        reason: 'got ${lists.map((e) => e?.toJson())}, expected ${{
          list1,
          list2,
        }.map((e) => e.toJson())}',
      );
    });

    test('for deleted task lists', () async {
      final list = TaskList(id: 'listId', title: 'list');
      await device.taskListService.upsertTaskList(list);
      await device.taskListService.removeTaskList('listId');

      final listActivities =
          (await device.taskListService.taskListActivities).toList();
      expect(listActivities.length, 1);
      expect(listActivities.first.isDeleted, true);
    });

    test('for updated task lists', () async {
      final list = TaskList(id: 'listId', title: 'list');
      await device.taskListService.upsertTaskList(list);
      await device.taskListService.upsertTaskList(list..title = 'a new title');

      final listActivities =
          (await device.taskListService.taskListActivities).toList();
      expect(listActivities.length, 2);
      listActivities.forEach((activity) {
        expect(activity.taskList, list);
        expect(activity.id, 'listId');
      });
      expect(
        listActivities.where((activity) => activity.isPropertyUpdate).length,
        1,
      );
    });

    test('for multiple updates in one task list', () async {
      final list = TaskList(
        id: 'listId',
        title: 'list',
        sortBy: SortOption.Title,
      );
      await device.taskListService.upsertTaskList(list);
      await device.taskListService.upsertTaskList(list..title = 'a new title');
      await device.taskListService
          .upsertTaskList(list..sortBy = SortOption.DueDate);

      final listActivities =
          (await device.taskListService.taskListActivities).toList();
      expect(listActivities.length, 3);
      listActivities.forEach((activity) {
        expect(activity.taskList, list);
        expect(activity.id, 'listId');
      });
      expect(
        listActivities.where((activity) => activity.isPropertyUpdate).length,
        2,
      );
    });

    test('of all types', () async {
      final list = TaskList(id: 'listId', title: 'list');
      final task = Task(title: 'task');
      await device.taskListService.upsertTaskList(list);
      await device.taskListService.upsertTask('listId', task);

      final allActivities =
          (await device.taskListService.allActivities).toList();
      expect(allActivities.length, 2);
      final taskActivities = allActivities.whereType<TaskActivity>().toList();
      expect(taskActivities.length, 1);
      expect(taskActivities.first.task, task);
      final listActivities =
          allActivities.whereType<TaskListActivity>().toList();
      expect(listActivities.length, 1);
      expect(listActivities.first.taskList, list);
    });
  });

  tearDown(() async {
    await device.close();
  });
}
