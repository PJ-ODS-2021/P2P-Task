import 'dart:convert';

import 'package:lww_crdt/lww_crdt.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/models/task_list.dart';
import 'package:p2p_task/services/change_callback_provider.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:p2p_task/utils/log_mixin.dart';
import 'package:uuid/uuid.dart';

import 'activity_record.dart';
import 'crdt_task_helper.dart';
import 'crdt_task_list_helper.dart';

typedef _TaskListCollectionCrdtType = MapCrdtRoot<String, TaskListCrdtType>;

class TaskListService with LogMixin, ChangeCallbackProvider {
  final String _crdtTaskListKey = 'crdtTaskLists';

  final KeyValueRepository _keyValueRepository;
  final IdentityService _identityService;
  final SyncService? _syncService;

  TaskListService(
    this._keyValueRepository,
    this._identityService,
    this._syncService,
  );

  Future<Iterable<TaskListActivity>> get taskListActivities async =>
      CrdtTaskListHelper.decodeTaskListActivities(
        await _readAndDecodeTaskListCollectionCrdt(),
      );

  Future<Iterable<TaskActivity>> get taskActivities async =>
      CrdtTaskHelper.decodeTaskActivities(
        await _readAndDecodeTaskListCollectionCrdt(),
      );

  Future<Iterable<ActivityRecord>> get allActivities async =>
      _readAndDecodeTaskListCollectionCrdt().then((crdt) => [
            CrdtTaskListHelper.decodeTaskListActivities(crdt),
            CrdtTaskHelper.decodeTaskActivities(crdt),
          ].expand((v) => v));

  Future<Iterable<Task>> get allTasks async =>
      (await taskLists).map((taskList) => taskList.elements).expand((e) => e);

  Future<Iterable<TaskList>> get taskLists async => (await _taskListRecords)
      .where((record) => !record.isDeleted)
      .map((record) => record.value!);

  Future<TaskList?> getTaskListById(String taskListId) async =>
      (await _taskListRecordMap)[taskListId]?.value;

  Future<Iterable<Record<TaskList>>> get _taskListRecords async =>
      (await _taskListRecordMap).values;

  Future<Map<String, Record<TaskList>>> get _taskListRecordMap async =>
      CrdtTaskListHelper.decodeTaskLists(
        await _readAndDecodeTaskListCollectionCrdt(),
      );

  /// Returns false if the task list does not exist
  Future<bool> upsertTask(String taskListId, Task task) async {
    logger.info('Upsert task ${task.toJson()}');
    final crdt = await _readAndDecodeTaskListCollectionCrdt();
    final taskListCrdt = crdt.get(taskListId);
    if (taskListCrdt == null) return false;

    task.id ??= Uuid().v4();
    final taskNode = taskListCrdt.getRecord(task.id!);
    if (taskNode == null || taskNode.isDeleted) {
      taskListCrdt.put(task.id!, CrdtTaskHelper.encodeTask(task, parent: crdt));
    } else {
      taskListCrdt.updateValue(
        task.id!,
        (currentValue) =>
            CrdtTaskHelper.encodeTask(task, parent: crdt, base: currentValue)
              ..merge(currentValue),
      );
    }
    await _store(crdt, triggerSyncUpdate: true);

    return true;
  }

  /// Returns the id of the  new task list.
  ///
  /// If [ignoreTasks] is set to true, tasks that are contained in this list will not be stored.
  Future<void> upsertTaskList(
    TaskList taskList, {
    bool ignoreTasks = false,
  }) async {
    logger.info('Upsert task list ${taskList.toJson()}');
    final crdt = await _readAndDecodeTaskListCollectionCrdt();
    taskList.id ??= Uuid().v4();
    final taskListNode = crdt.getRecord(taskList.id!);
    if (taskListNode == null || taskListNode.isDeleted) {
      crdt.put(
        taskList.id!,
        CrdtTaskListHelper.encodeTaskList(
          taskList,
          parent: crdt,
          ignoreTasks: ignoreTasks,
        ),
      );
    } else {
      crdt.updateValue(
        taskList.id!,
        (currentValue) => CrdtTaskListHelper.encodeTaskList(
          taskList,
          parent: crdt,
          base: currentValue,
          ignoreTasks: ignoreTasks,
        )..merge(currentValue),
      );
    }
    await _store(crdt, triggerSyncUpdate: true);
  }

  Future<void> removeTaskList(String taskListId) async {
    final update = (await _readAndDecodeTaskListCollectionCrdt())
      ..delete(taskListId);
    await _store(update, triggerSyncUpdate: true);
  }

  Future<void> removeTask(String taskListId, String taskId) async {
    final update = (await _readAndDecodeTaskListCollectionCrdt())
      ..get(taskListId)?.delete(taskId);
    await _store(update, triggerSyncUpdate: true);
  }

  Future<void> delete() async {
    await _keyValueRepository.purge(key: _crdtTaskListKey);
    invokeChangeCallback();
    await _syncService?.run(runOnSyncOnUpdate: true);
  }

  /// This method can be quite slow because all tasks need to be loaded
  Future<int> count() async {
    return (await allTasks).length;
  }

  Future<void> mergeCrdtJson(String otherJson) async {
    logger.info('Merging with $otherJson');
    final self = (await _readAndDecodeTaskListCollectionCrdt());
    final other =
        CrdtTaskListHelper.decodeTaskListsCrdt(otherJson, logger: logger);
    if (other == null) return;
    self.merge(other);
    logger.info('Merge result ${self.toJson()}');
    await _store(self, triggerSyncUpdate: false);
  }

  Future<String> crdtToJson() async =>
      _readTaskListCollectionCrdtStringFromDatabase().then((v) => v ?? '');

  Future<_TaskListCollectionCrdtType>
      _readAndDecodeTaskListCollectionCrdt() async =>
          CrdtTaskListHelper.decodeTaskListsCrdt(
            await _readTaskListCollectionCrdtStringFromDatabase(),
            peerId: await _identityService.peerId,
            logger: logger,
          )!;

  Future<String?> _readTaskListCollectionCrdtStringFromDatabase() async =>
      await _keyValueRepository.get<String>(_crdtTaskListKey);

  Future<void> _store(
    _TaskListCollectionCrdtType value, {
    required bool triggerSyncUpdate,
  }) async {
    await _keyValueRepository.put(
      _crdtTaskListKey,
      jsonEncode(value.toJson(
        valueEncode: (taskList) => taskList.toJson(
          valueEncode: (task) => task is TaskCrdtType ? task.toJson() : task,
        ),
      )),
    );
    invokeChangeCallback();
    logger.info('notifying task list change');
    if (triggerSyncUpdate) {
      await _syncService?.run(runOnSyncOnUpdate: true);
    }
  }
}
