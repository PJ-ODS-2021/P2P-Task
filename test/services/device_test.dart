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

  test('distinct task lists on distinct devices', () async {
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

    final device1TaskLists =
        (await devices[0].taskListService.getTaskLists()).toList();
    expect(device1TaskLists.length, 1);
    expect(device1TaskLists.first.id, 'id1');
    expect(device1TaskLists.first.title, 'list1');
    expect(device1TaskLists.first.elements, [task1]);

    final device2TaskLists =
        (await devices[1].taskListService.getTaskLists()).toList();
    expect(device2TaskLists.length, 1);
    expect(device2TaskLists.first.id, 'id2');
    expect(device2TaskLists.first.title, 'list2');
    expect(device2TaskLists.first.elements, [task2]);
  });
}
