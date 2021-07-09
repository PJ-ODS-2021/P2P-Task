import 'package:lww_crdt/lww_crdt.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/models/task_list.dart';

import 'activity_record.dart';
import 'crdt_task_list_helper.dart';

typedef TaskCrdtType = MapCrdtNode<String, dynamic>;

class CrdtTaskHelper {
  CrdtTaskHelper._();

  static Task decodeTask(TaskCrdtType crdt, {String? id}) {
    final task = Task.fromJson(crdt.map);
    if (id != null) task.id = id;

    return task;
  }

  static List<TaskActivity> getTaskActivities(
    MapEntry<String, Record> entry,
    String taskListId,
  ) {
    if (entry.value.isDeleted) {
      return [
        _taskActivityFromRecordEntry(
          entry,
          taskListId: taskListId,
        ),
      ];
    }

    // decode task and get recursive updates more recent than the task node clock value
    final taskCrdt = entry.value.value as TaskCrdtType;
    final task = decodeTask(taskCrdt, id: entry.key);
    final valueClocks = taskCrdt.records.values
        .map((record) => record.clock)
        .toSet()
          ..removeWhere((clock) => clock <= entry.value.clock);

    return [
      _taskActivityFromRecordEntry(
        entry,
        taskListId: taskListId,
        task: task,
      ),
      for (final valueClock in valueClocks)
        TaskActivity(
          valueClock.node,
          DateTime.fromMillisecondsSinceEpoch(valueClock.timestamp),
          entry.key,
          task,
          taskListId,
          true,
        ),
    ];
  }

  static TaskActivity _taskActivityFromRecordEntry(
    MapEntry<String, Record> entry, {
    required String taskListId,
    Task? task,
    bool isRecursiveUpdate = false,
  }) {
    return TaskActivity(
      entry.value.clock.node,
      DateTime.fromMillisecondsSinceEpoch(
        entry.value.clock.timestamp,
      ),
      entry.key,
      task,
      taskListId,
      isRecursiveUpdate,
    );
  }

  /// If [base] is set, only add changed entries from [task] compared to [base] to the crdt node
  static TaskCrdtType encodeTask(
    Task task, {
    required MapCrdtRoot parent,
    TaskCrdtType? base,
  }) {
    final taskCrdt = TaskCrdtType(parent);
    final taskJson = task.toJson()
      ..remove('id'); // TODO: hacky, hard to maintain
    if (base == null) {
      taskCrdt.putAll(taskJson);
    } else {
      taskCrdt.putAll(
        taskJson..removeWhere((key, value) => base.get(key) == value),
      );
    }

    return taskCrdt;
  }

  static Iterable<TaskActivity> decodeTaskActivities(
    MapCrdt<String, TaskListCrdtType> crdt,
  ) {
    return crdt.records.entries
        .where((taskListRecordEntry) => !taskListRecordEntry.value.isDeleted)
        .map((taskListRecordEntry) =>
            taskListRecordEntry.value.value!.records.entries.where((entry) {
              return entry.value.value is TaskCrdtType ||
                  (entry.value.isDeleted &&
                      !TaskList.crdtMembers.contains(entry.key));
            }).map(
              (entry) => getTaskActivities(entry, taskListRecordEntry.key),
            ))
        .expand((v) => v.expand((v) => v));
  }
}
