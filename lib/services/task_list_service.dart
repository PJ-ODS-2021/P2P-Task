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

typedef _TaskCrdtType = MapCrdtNode<String, dynamic>;
typedef _TaskListCrdtType = MapCrdtNode<String, dynamic>;
typedef _TaskListCollectionCrdtType = MapCrdtRoot<String, _TaskListCrdtType>;

class TaskListService with LogMixin, ChangeCallbackProvider {
  final String _crdtTaskListKey = 'crdtTaskLists';

  final KeyValueRepository _keyValueRepository;
  final IdentityService _identityService;
  final SyncService _syncService;

  TaskListService(
    this._keyValueRepository,
    this._identityService,
    this._syncService,
  );

  Future<Iterable<Task>> get allTasks async =>
      (await taskLists).map((taskList) => taskList.elements).expand((e) => e);

  Future<Iterable<TaskList>> get taskLists async => (await taskListRecords)
      .where((record) => !record.isDeleted)
      .map((record) => record.value!);

  Future<Iterable<Record<TaskList>>> get taskListRecords async =>
      (await taskListRecordMap).values;

  Future<Map<String, Record<TaskList>>> get taskListRecordMap async =>
      _decodeTaskListCollection(await _readAndDecodeTaskListCollectionCrdt());

  Future<Record<TaskList>?> getTaskListRecordById(String taskListId) async =>
      (await taskListRecordMap)[taskListId];

  Future<TaskList?> getTaskListById(String taskListId) async =>
      (await taskListRecordMap)[taskListId]?.value;

  Future<Iterable<Task>> getTasksFromList(String taskListId) async =>
      getTaskListById(taskListId)
          .then((taskList) => taskList != null ? taskList.elements : []);

  /// Returns false if the task list does not exist
  Future<bool> upsertTask(String taskListId, Task task) async {
    l.info('Upsert task ${task.toJson()}');
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

    await _store(crdt);
    await _syncService.run();

    return true;
  }

  /// Returns the id of the  new task list.
  ///
  /// If [ignoreTasks] is set to true, tasks that are contained in this list will not be stored.
  Future<void> upsertTaskList(
    TaskList taskList, {
    bool ignoreTasks = false,
  }) async {
    l.info('Upsert task list ${taskList.toJson()}');
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

    await _store(crdt);
    await _syncService.run();
  }

  Future<void> removeTaskList(String taskListId) async {
    final update = (await _readAndDecodeTaskListCollectionCrdt())
      ..delete(taskListId);
    await _store(update);
    await _syncService.run();
  }

  Future<void> removeTask(String taskListId, String taskId) async {
    final update = (await _readAndDecodeTaskListCollectionCrdt())
      ..get(taskListId)?.delete(taskId);
    await _store(update);
    await _syncService.run();
  }

  Future<void> delete() async {
    await _keyValueRepository.purge(key: _crdtTaskListKey);
    invokeChangeCallback();
    await _syncService.run();
  }

  Future<int> count() async {
    return (await allTasks).length;
  }

  Future<void> _store(_TaskListCollectionCrdtType value) async {
    await _keyValueRepository.put(
      _crdtTaskListKey,
      jsonEncode(value.toJson(
        valueEncode: (taskList) => taskList.toJson(
          valueEncode: (task) => task is _TaskCrdtType ? task.toJson() : task,
        ),
      )),
    );
    invokeChangeCallback();
    l.info('notifying task list change');
  }

  Future<String> crdtToJson() async =>
      _readTaskListCollectionCrdtStringFromDatabase().then((v) => v ?? '');

  Future<void> mergeCrdtJson(String otherJson) async {
    l.info('Merging with $otherJson');
    final self = (await _readAndDecodeTaskListCollectionCrdt());
    final other = _decodeTaskListCollectionCrdt(otherJson);
    if (other == null) return;
    self.merge(other);
    l.info('Merge result ${self.toJson()}');
    await _store(self);
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

    return peerId != null
        ? _validateCrdtPeer(taskListCrdt, peerId)
        : taskListCrdt;
  }

  _TaskListCollectionCrdtType _validateCrdtPeer(
    _TaskListCollectionCrdtType crdt,
    String expectedPeer,
  ) {
    if (crdt.node != expectedPeer) {
      l.severe(
        'Got invalid node id when reading task list from disk (disk != peerId): "${crdt.node}" != "$expectedPeer"',
      );
      if (crdt.containsNode(expectedPeer)) {
        l.severe(
          'A node with this peer id already exists. Changing disk node id (could indicate another device is using the same node id which is VERY unlikely and breaks the algorithm)',
        );
      } else {
        l.warning(
          'Changing disk node id. The old node id might be dead from now on',
        );
        crdt.addNode(expectedPeer);
      }

      // TODO: This won't change the parent in the sub-nodes
      return _TaskListCollectionCrdtType(
        expectedPeer,
        nodes: crdt.nodes.toSet(),
        vectorClock: crdt.vectorClock,
        records: crdt.records,
        validateRecords: false,
      );
    }

    return crdt;
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

  Map<String, Record<TaskList>> _decodeTaskListCollection(
    _TaskListCollectionCrdtType crdt,
  ) {
    return crdt.records.map((key, record) => MapEntry(
          key,
          Record<TaskList>(
            clock: record.clock,
            value: record.isDeleted
                ? null
                : _decodeTaskList(record.value!, id: key),
          ),
        ));
  }

  TaskList _decodeTaskList(_TaskListCrdtType crdt, {String? id}) {
    const taskListCrdtMembers = ['isShared', 'title', 'sortBy'];
    final tasks = crdt.records.entries
        .where((entry) =>
            !entry.value.isDeleted && entry.value.value is _TaskCrdtType)
        .map((entry) => _decodeTask(entry.value.value, id: entry.key));

    return TaskList.fromJson({
      'id': id,
      'elements': [],
    }..addAll(Map.fromEntries(
        taskListCrdtMembers.map((e) => MapEntry(e, crdt.get(e))),
      )))
      ..elements.addAll(tasks);
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

class TaskRecord {
  final Task? task;
  final String peerId;
  final DateTime timestamp;

  const TaskRecord(this.task, this.peerId, this.timestamp);
}
