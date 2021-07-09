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

typedef _TaskCrdtType = MapCrdtNode<String, dynamic>;
typedef _TaskListCrdtType = MapCrdtNode<String, dynamic>;
typedef _TaskListCollectionCrdtType = MapCrdtRoot<String, _TaskListCrdtType>;

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
      _decodeTaskListActivities(await _readAndDecodeTaskListCollectionCrdt());

  Future<Iterable<TaskActivity>> get taskActivities async =>
      _decodeTaskActivities(await _readAndDecodeTaskListCollectionCrdt());

  Future<Iterable<ActivityRecord>> get allActivities async =>
      _readAndDecodeTaskListCollectionCrdt().then((crdt) => [
            _decodeTaskListActivities(crdt),
            _decodeTaskActivities(crdt),
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
      _decodeTaskListCollection(await _readAndDecodeTaskListCollectionCrdt());

  /// Returns false if the task list does not exist
  Future<bool> upsertTask(String taskListId, Task task) async {
    logger.info('Upsert task ${task.toJson()}');
    final crdt = await _readAndDecodeTaskListCollectionCrdt();
    final taskListCrdt = crdt.get(taskListId);
    if (taskListCrdt == null) return false;

    task.id ??= Uuid().v4();
    final taskNode = taskListCrdt.getRecord(task.id!);
    if (taskNode == null || taskNode.isDeleted) {
      taskListCrdt.put(task.id!, _encodeTask(task, parent: crdt));
    } else {
      taskListCrdt.updateValue(
        task.id!,
        (currentValue) => _encodeTask(task, parent: crdt, base: currentValue)
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
        _encodeTaskList(
          taskList,
          parent: crdt,
          ignoreTasks: ignoreTasks,
        ),
      );
    } else {
      crdt.updateValue(
        taskList.id!,
        (currentValue) => _encodeTaskList(
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

  Future<void> _store(
    _TaskListCollectionCrdtType value, {
    required bool triggerSyncUpdate,
  }) async {
    await _keyValueRepository.put(
      _crdtTaskListKey,
      jsonEncode(value.toJson(
        valueEncode: (taskList) => taskList.toJson(
          valueEncode: (task) => task is _TaskCrdtType ? task.toJson() : task,
        ),
      )),
    );
    invokeChangeCallback();
    logger.info('notifying task list change');
    if (triggerSyncUpdate) {
      await _syncService?.run(runOnSyncOnUpdate: true);
    }
  }

  Future<String> crdtToJson() async =>
      _readTaskListCollectionCrdtStringFromDatabase().then((v) => v ?? '');

  Future<void> mergeCrdtJson(String otherJson) async {
    logger.info('Merging with $otherJson');
    final self = (await _readAndDecodeTaskListCollectionCrdt());
    final other = _decodeTaskListCollectionCrdt(otherJson);
    if (other == null) return;
    self.merge(other);
    logger.info('Merge result ${self.toJson()}');
    await _store(self, triggerSyncUpdate: false);
  }

  Future<_TaskListCollectionCrdtType>
      _readAndDecodeTaskListCollectionCrdt() async =>
          _decodeTaskListCollectionCrdt(
            await _readTaskListCollectionCrdtStringFromDatabase(),
            await _identityService.peerId,
          )!;

  Future<String?> _readTaskListCollectionCrdtStringFromDatabase() async =>
      await _keyValueRepository.get<String>(_crdtTaskListKey);

  /// Can only return null if [peerId] is null
  _TaskListCollectionCrdtType? _decodeTaskListCollectionCrdt(
    String? value, [
    String? peerId,
  ]) {
    final Map<String, dynamic> json =
        value != null && value.isNotEmpty ? jsonDecode(value) : {};
    if (json.isEmpty) {
      return peerId != null ? _TaskListCollectionCrdtType(peerId) : null;
    }
    final taskListCrdt = _crdtFromJson(json);
    if (peerId != null) _validateCrdtPeer(taskListCrdt, peerId);

    return taskListCrdt;
  }

  /// Changes the crdt node if [expectedNode] differs from the [crdt].node
  void _validateCrdtPeer(
    _TaskListCollectionCrdtType crdt,
    String expectedNode,
  ) {
    if (crdt.node != expectedNode) {
      logger.severe(
        'Got invalid node id when reading task list from disk (disk != peerId): "${crdt.node}" != "$expectedNode". Changing node id, the old node id might be dead for now on',
      );
      if (crdt.containsNode(expectedNode)) {
        logger.severe(
          'A node with this peer id already exists. This could indicate another device is using the same node id which is VERY unlikely and potentially breaks the algorithm',
        );
      }
      crdt.changeNode(expectedNode);
    }
  }

  _TaskListCollectionCrdtType _crdtFromJson(Map<String, dynamic> json) {
    return _TaskListCollectionCrdtType.fromJson(
      json,
      lateValueDecode: (crdt, taskListJson) => _TaskListCrdtType.fromJson(
        taskListJson,
        parent: crdt,
        valueDecode: (taskJson) => taskJson is Map<String, dynamic>
            ? _TaskCrdtType.fromJson(taskJson, parent: crdt)
            : taskJson,
      ),
    );
  }

  Iterable<TaskListActivity> _decodeTaskListActivities(
    _TaskListCollectionCrdtType crdt,
  ) {
    return crdt.records.entries.map((taskRecordEntry) {
      final taskList = taskRecordEntry.value.isDeleted
          ? null
          : _decodeTaskList(
              taskRecordEntry.value.value!,
              id: taskRecordEntry.key,
              decodeTasks: false,
            );
      final propertyUpdateClocks = taskRecordEntry.value.value?.records.entries
          .where((taskRecordEntry) =>
              !taskRecordEntry.value.isDeleted &&
              !(taskRecordEntry.value.value is _TaskCrdtType))
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

  Iterable<TaskActivity> _decodeTaskActivities(
    _TaskListCollectionCrdtType crdt,
  ) {
    return crdt.records.entries
        .where((taskListRecordEntry) => !taskListRecordEntry.value.isDeleted)
        .map((taskListRecordEntry) =>
            taskListRecordEntry.value.value!.records.entries.where((entry) {
              return entry.value.value is _TaskCrdtType ||
                  (entry.value.isDeleted &&
                      !TaskList.crdtMembers.contains(entry.key));
            }).map(
              (entry) => _getTaskActivities(entry, taskListRecordEntry.key),
            ))
        .expand((v) => v.expand((v) => v));
  }

  List<TaskActivity> _getTaskActivities(
    MapEntry<String, Record<dynamic>> entry,
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
    final taskCrdt = entry.value.value as _TaskCrdtType;
    final task = _decodeTask(taskCrdt, id: entry.key);
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

  TaskActivity _taskActivityFromRecordEntry(
    MapEntry<String, Record<dynamic>> entry, {
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

  Map<String, Record<TaskList>> _decodeTaskListCollection(
    _TaskListCollectionCrdtType crdt, {
    bool decodeTasks = true,
  }) {
    return crdt.records.map((key, record) => MapEntry(
          key,
          Record<TaskList>(
            clock: record.clock,
            value: record.isDeleted
                ? null
                : _decodeTaskList(
                    record.value!,
                    id: key,
                    decodeTasks: decodeTasks,
                  ),
          ),
        ));
  }

  TaskList _decodeTaskList(
    _TaskListCrdtType crdt, {
    String? id,
    bool decodeTasks = true,
  }) {
    final tasks = decodeTasks
        ? crdt.records.entries
            .where((entry) =>
                !entry.value.isDeleted && entry.value.value is _TaskCrdtType)
            .map((entry) => _decodeTask(entry.value.value, id: entry.key))
        : null;

    return TaskList.fromJson({
      'id': id,
      'elements': [],
    }..addAll(Map.fromEntries(
        TaskList.crdtMembers.map((e) => MapEntry(e, crdt.get(e))),
      )))
      ..elements.addAll(tasks ?? []);
  }

  Task _decodeTask(_TaskCrdtType crdt, {String? id}) {
    final task = Task.fromJson(crdt.map);
    if (id != null) task.id = id;

    return task;
  }

  _TaskListCrdtType _encodeTaskList(
    TaskList taskList, {
    required _TaskListCollectionCrdtType parent,
    _TaskListCrdtType? base,
    bool ignoreTasks = false,
  }) {
    final taskListCrdt = _TaskListCrdtType(parent);
    final taskListJson = taskList.toJson()
      ..remove('id')
      ..remove('elements'); // TODO: hacky, hard to maintain
    if (base == null) {
      if (!ignoreTasks) {
        taskListJson.addAll(Map.fromEntries(taskList.elements.map(
          (task) => MapEntry(
            task.id ?? Uuid().v4(),
            _encodeTask(task, parent: parent),
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
              _encodeTask(
                task,
                parent: parent,
                base: baseTask is _TaskCrdtType ? baseTask : null,
              ),
            );
          },
        )));
      }
      taskListCrdt.putAll(taskListJson);
    }

    return taskListCrdt;
  }

  /// If [base] is set, only add changed entries from [task] to the crdt node
  _TaskCrdtType _encodeTask(
    Task task, {
    required _TaskListCollectionCrdtType parent,
    _TaskCrdtType? base,
  }) {
    final taskCrdt = _TaskCrdtType(parent);
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
}
