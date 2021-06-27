import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/models/task_list.dart';
import 'package:uuid/uuid.dart';

import '../utils/device_task_list.dart';

void main() {
  late DeviceTaskList device;

  setUp(() async {
    device = await DeviceTaskList.create(name: 'device');
  });

  test('create task list', () async {
    final id = Uuid().v4();
    await device.taskListService
        .upsertTaskList(TaskList(id: id, title: 'list1'));
    final taskListRecordMap = await device.taskListService.taskLists;
    expect(taskListRecordMap.map((e) => e.id!), [id]);
    expect(taskListRecordMap.first.title, 'list1');
  });

  test('should store and retrieve tasks after first task is deleted', () async {
    const taskTitle1 = 'Catch a cat falling from the sky';
    const taskTitle2 = 'Drink a cold cat';

    await device.taskListService
        .upsertTaskList(TaskList(id: 'id1', title: 'list1'));
    await device.taskListService.upsertTask('id1', Task(title: taskTitle1));
    var tasks = (await device.taskListService.allTasks).toList();
    expect(tasks.length, 1);
    expect(tasks.first.title, taskTitle1);
    final taskId = tasks.first.id!;
    expect(taskId, isNot(null));

    await device.taskListService.removeTask('id1', taskId);
    tasks = (await device.taskListService.allTasks).toList();
    expect(tasks.isEmpty, true);

    await device.taskListService.upsertTask('id1', Task(title: taskTitle2));
    tasks = (await device.taskListService.allTasks).toList();

    expect(tasks.length, 1);
    expect(tasks.first.title, taskTitle2);
  });

  test('should retrieve tasks with allTaskRecords', () async {
    final task1 = Task(title: 'Catch a cat falling from the sky');
    final task2 = Task(title: 'Drink a cold cat');
    await device.taskListService
        .upsertTaskList(TaskList(id: 'id1', title: 'list1'));
    await device.taskListService.upsertTask('id1', task1);
    await device.taskListService.upsertTask('id1', task2);

    final allTaskRecords =
        (await device.taskListService.allTaskRecords).toList();
    expect(allTaskRecords.length, 2);
    expect(allTaskRecords.map((v) => v.task).toSet(), {task1, task2});
    expect(allTaskRecords.map((v) => v.taskListId).toList(), ['id1', 'id1']);
  });

  test('should retrieve deleted task record with allTaskRecords', () async {
    final task1 = Task(title: 'Catch a cat falling from the sky');
    await device.taskListService
        .upsertTaskList(TaskList(id: 'id1', title: 'list1'));
    await device.taskListService.upsertTask('id1', task1);
    await device.taskListService.removeTask('id1', task1.id!);

    final allTaskRecords =
        (await device.taskListService.allTaskRecords).toList();
    expect(allTaskRecords.length, 1);
    expect(allTaskRecords.first.task, null);
  });

  tearDown(() async {
    await device.close();
  });
}
