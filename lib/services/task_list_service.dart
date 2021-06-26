import 'dart:convert';

import 'package:lww_crdt/lww_crdt.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/services/change_callback_provider.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:p2p_task/utils/log_mixin.dart';
import 'package:uuid/uuid.dart';

typedef _TaskCrdtType = MapCrdtNode<String, dynamic>;
typedef _TaskListCrdtType = MapCrdtRoot<String, _TaskCrdtType>;

class TaskListService with LogMixin, ChangeCallbackProvider {
  final String _crdtTaskListKey = 'crdtTaskList';

  final KeyValueRepository _keyValueRepository;
  final IdentityService _identityService;
  final SyncService _syncService;

  TaskListService(
    this._keyValueRepository,
    this._identityService,
    this._syncService,
  );

  Future<Iterable<Task>> get tasks async =>
      _decodeTaskListMap(await _readAndDecodeTaskListCrdt())
          .values
          .where((record) => !record.isDeleted)
          .map((record) => record.value!);

  Future<Iterable<TaskRecord>> get taskRecords async =>
      _decodeTaskListMap(await _readAndDecodeTaskListCrdt())
          .values
          .map((record) => TaskRecord(
                record.value,
                record.clock.node,
                DateTime.fromMillisecondsSinceEpoch(record.clock.timestamp),
              ));

  Future<void> upsert(Task task) async {
    l.info('Upsert task ${task.toJson()}');
    final crdt = (await _readAndDecodeTaskListCrdt());
    task.id ??= Uuid().v4();
    final taskNode = crdt.getRecord(task.id!);
    if (taskNode == null || taskNode.isDeleted) {
      crdt.put(task.id!, _encodeTask(task, parent: crdt));
    } else {
      crdt.updateValue(
        task.id!,
        (p0) => _encodeTask(task, parent: crdt, base: taskNode.value!)
          ..merge(taskNode.value!),
      );
    }
    await _store(crdt);
    await _syncService.run();
  }

  Future<void> remove(Task task) async {
    final update = (await _readAndDecodeTaskListCrdt())..delete(task.id!);
    await _store(update);
    await _syncService.run();
  }

  Future<void> delete() async {
    await _keyValueRepository.purge(key: _crdtTaskListKey);
    invokeChangeCallback();
    await _syncService.run();
  }

  Future<int> count() async {
    return (await tasks).length;
  }

  Future<void> _store(_TaskListCrdtType value) async {
    await _keyValueRepository.put(
      _crdtTaskListKey,
      jsonEncode(value.toJson(
        valueEncode: (v) => v.toJson(),
      )),
    );
    invokeChangeCallback();
    l.info('notifying task list change');
  }

  Future<String> crdtToJson() async =>
      _readTaskListCrdtStringFromDatabase().then((v) => v ?? '');

  Future<void> mergeCrdtJson(String otherJson) async {
    l.info('Merging with $otherJson');
    final self = (await _readAndDecodeTaskListCrdt());
    final other = _decodeTaskListCrdt(otherJson);
    if (other == null) return;
    self.merge(other);
    l.info('Merge result ${self.toJson()}');
    await _store(self);
  }

  Future<_TaskListCrdtType> _readAndDecodeTaskListCrdt() async =>
      _decodeTaskListCrdt(
        await _readTaskListCrdtStringFromDatabase(),
        await _identityService.peerId,
      )!;

  Future<String?> _readTaskListCrdtStringFromDatabase() async =>
      await _keyValueRepository.get<String>(_crdtTaskListKey);

  /// Can only return null if [peerId] is null
  _TaskListCrdtType? _decodeTaskListCrdt(String? value, [String? peerId]) {
    final Map<String, dynamic> taskListJson =
        value != null && value.isNotEmpty ? jsonDecode(value) : {};
    if (taskListJson.isEmpty) {
      return peerId != null ? _TaskListCrdtType(peerId) : null;
    }
    final taskListCrdt = _crdtFromJson(taskListJson);

    return peerId != null
        ? _validateCrdtPeer(taskListCrdt, peerId)
        : taskListCrdt;
  }

  _TaskListCrdtType _validateCrdtPeer(
    _TaskListCrdtType crdt,
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

      return _TaskListCrdtType(
        expectedPeer,
        nodes: crdt.nodes.toSet(),
        vectorClock: crdt.vectorClock,
        records: crdt.records,
        validateRecords: false,
      );
    }

    return crdt;
  }

  _TaskListCrdtType _crdtFromJson(Map<String, dynamic> json) {
    return _TaskListCrdtType.fromJson(
      json,
      lateValueDecode: (crdt, json) =>
          _TaskCrdtType.fromJson(json, parent: crdt),
    );
  }

  Map<String, Record<Task>> _decodeTaskListMap(_TaskListCrdtType crdt) {
    return crdt.records.map(
      (key, record) => MapEntry(
        key,
        Record<Task>(
          clock: record.clock,
          value: record.isDeleted ? null : _decodeTask(record.value!, id: key),
        ),
      ),
    );
  }

  Task _decodeTask(_TaskCrdtType crdt, {String? id}) {
    final task = Task.fromJson(crdt.map);
    if (id != null) task.id = id;

    return task;
  }

  /// If [base] is set, only add changed entries from [task] to the crdt node
  _TaskCrdtType _encodeTask(
    Task task, {
    required _TaskListCrdtType parent,
    MapCrdtNode<String, dynamic>? base,
  }) {
    final taskCrdt = _TaskCrdtType(parent);
    final taskJson = task.toJson()..remove('id');
    if (base == null) {
      taskJson.forEach((key, value) => taskCrdt.put(key, value));
    } else {
      taskJson.forEach((key, value) {
        if (base.get(key) != value) taskCrdt.put(key, value);
      });
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
