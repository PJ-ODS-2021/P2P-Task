import 'dart:convert';

import 'package:lww_crdt/lww_crdt.dart';
import 'package:p2p_task/models/task_list.dart';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';

import 'activity_record.dart';
import 'crdt_task_helper.dart';

typedef TaskListCrdtType = MapCrdtNode<String, dynamic>;

class CrdtTaskListHelper {
  CrdtTaskListHelper._();

  static TaskList decodeTaskList(
    TaskListCrdtType crdt, {
    String? id,
    bool decodeTasks = true,
  }) {
    final tasks = decodeTasks
        ? crdt.records.entries
            .where((entry) =>
                !entry.value.isDeleted && entry.value.value is TaskCrdtType)
            .map((entry) =>
                CrdtTaskHelper.decodeTask(entry.value.value, id: entry.key))
        : null;

    return TaskList.fromJson({
      'id': id,
      'elements': [],
    }..addAll(Map.fromEntries(
        TaskList.crdtMembers.map((e) => MapEntry(e, crdt.get(e))),
      )))
      ..elements.addAll(tasks ?? []);
  }

  static TaskListCrdtType encodeTaskList(
    TaskList taskList, {
    required MapCrdtRoot parent,
    TaskListCrdtType? base,
    bool ignoreTasks = false,
  }) {
    final taskListCrdt = TaskListCrdtType(parent);
    final taskListJson = taskList.toJson()
      ..remove('id')
      ..remove('elements'); // TODO: hacky, hard to maintain
    if (base == null) {
      if (!ignoreTasks) {
        taskListJson.addAll(Map.fromEntries(taskList.elements.map(
          (task) => MapEntry(
            task.id ?? Uuid().v4(),
            CrdtTaskHelper.encodeTask(task, parent: parent),
          ),
        )));
      }
      taskListCrdt.putAll(taskListJson);
    } else {
      taskListJson.removeWhere((key, value) => base.get(key) == value);
      if (!ignoreTasks) {
        taskListJson.addAll(Map.fromEntries(taskList.elements.map(
          (task) {
            task.id ??= Uuid().v4();
            final baseTask = base.get(task.id!);

            return MapEntry(
              task.id!,
              CrdtTaskHelper.encodeTask(
                task,
                parent: parent,
                base: baseTask is TaskCrdtType ? baseTask : null,
              ),
            );
          },
        )));
      }
      taskListCrdt.putAll(taskListJson);
    }

    return taskListCrdt;
  }

  static Iterable<TaskListActivity> decodeTaskListActivities(
    MapCrdt<String, TaskListCrdtType> crdt,
  ) {
    return crdt.records.entries.map((taskRecordEntry) {
      final taskList = taskRecordEntry.value.isDeleted
          ? null
          : decodeTaskList(
              taskRecordEntry.value.value!,
              id: taskRecordEntry.key,
              decodeTasks: false,
            );
      final propertyUpdateClocks = taskRecordEntry.value.value?.records.entries
          .where((taskRecordEntry) =>
              !taskRecordEntry.value.isDeleted &&
              !(taskRecordEntry.value.value is TaskCrdtType))
          .map((taskRecordEntry) => taskRecordEntry.value.clock)
          .toSet()
            ?..removeWhere((clock) => clock <= taskRecordEntry.value.clock);

      return [
        TaskListActivity(
          taskRecordEntry.value.clock.node,
          DateTime.fromMillisecondsSinceEpoch(
            taskRecordEntry.value.clock.timestamp,
          ),
          taskRecordEntry.key,
          taskList,
          false,
        ),
        if (propertyUpdateClocks != null)
          for (final clockValue in propertyUpdateClocks)
            TaskListActivity(
              clockValue.node,
              DateTime.fromMillisecondsSinceEpoch(clockValue.timestamp),
              taskRecordEntry.key,
              taskList,
              true,
            ),
      ];
    }).expand((v) => v);
  }

  static Map<String, Record<TaskList>> decodeTaskLists(
    MapCrdt<String, TaskListCrdtType> crdt, {
    bool decodeTasks = true,
  }) {
    return crdt.records.map((key, record) => MapEntry(
          key,
          Record<TaskList>(
            clock: record.clock,
            value: record.isDeleted
                ? null
                : decodeTaskList(
                    record.value!,
                    id: key,
                    decodeTasks: decodeTasks,
                  ),
          ),
        ));
  }

  static MapCrdtRoot<String, TaskListCrdtType> taskListCrdtFromJson(
    Map<String, dynamic> json,
  ) {
    return MapCrdtRoot<String, TaskListCrdtType>.fromJson(
      json,
      lateValueDecode: (crdt, taskListJson) => TaskListCrdtType.fromJson(
        taskListJson,
        parent: crdt,
        valueDecode: (taskJson) => taskJson is Map<String, dynamic>
            ? TaskCrdtType.fromJson(taskJson, parent: crdt)
            : taskJson,
      ),
    );
  }

  /// Will never return null if [peerId] is not null
  static MapCrdtRoot<String, TaskListCrdtType>? decodeTaskListsCrdt(
    String? jsonSource, {
    String? peerId,
    Logger? logger,
  }) {
    final Map<String, dynamic> json =
        jsonSource != null && jsonSource.isNotEmpty
            ? jsonDecode(jsonSource)
            : {};
    if (json.isEmpty) {
      return peerId != null
          ? MapCrdtRoot<String, TaskListCrdtType>(peerId)
          : null;
    }
    final taskListCrdt = taskListCrdtFromJson(json);
    if (peerId != null) _validateCrdtPeer(taskListCrdt, peerId, logger);

    return taskListCrdt;
  }

  static void _validateCrdtPeer(
    MapCrdtRoot<String, TaskListCrdtType> crdt,
    String expectedNode,
    Logger? logger,
  ) {
    if (crdt.node != expectedNode) {
      logger?.severe(
        'Got invalid node id when reading task list from disk (disk != peerId): "${crdt.node}" != "$expectedNode". Changing node id, the old node id might be dead for now on',
      );
      if (crdt.containsNode(expectedNode)) {
        logger?.severe(
          'A node with this peer id already exists. This could indicate another device is using the same node id which is VERY unlikely and potentially breaks the algorithm',
        );
      }
      crdt.changeNode(expectedNode);
    }
  }
}
