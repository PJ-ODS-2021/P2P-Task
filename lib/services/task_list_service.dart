import 'dart:convert';

import 'package:lww_crdt/lww_crdt.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/services/change_callback_provider.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:p2p_task/utils/log_mixin.dart';
import 'package:uuid/uuid.dart';

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

  Future<Iterable<Task>> get tasks async => (await _taskListCrdt).values;

  Future<Iterable<TaskRecord>> get taskRecords async => (await _taskListCrdt)
      .records
      .values
      .where((record) => !record.isDeleted)
      .map((record) => TaskRecord(
            record.value!,
            record.clock.node,
            DateTime.fromMillisecondsSinceEpoch(record.clock.timestamp),
          ));

  Future upsert(Task task) async {
    l.info('Upsert task ${task.toJson()}');
    final id = Uuid().v4();
    final update = (await _taskListCrdt)
      ..put(task.id ?? id, task..id = (task.id ?? id));
    await _store(update);
    await _syncService.run();
  }

  Future remove(Task task) async {
    final update = (await _taskListCrdt)..delete(task.id!);
    await _store(update);
    await _syncService.run();
  }

  Future delete() async {
    await _keyValueRepository.purge(key: _crdtTaskListKey);
    invokeChangeCallback();
    await _syncService.run();
  }

  Future<int> count() async {
    return (await tasks).length;
  }

  Future<void> _store(MapCrdt<String, Task> update) async {
    await _keyValueRepository.put(
      _crdtTaskListKey,
      jsonEncode(update.toJson()),
    );
    invokeChangeCallback();
    l.info('notifying task list change');
  }

  Future<String> crdtToJson() async {
    return jsonEncode((await _taskListCrdt).toJson(
      valueEncode: (task) => task.toJson(),
    ));
  }

  Future mergeCrdtJson(String otherJson) async {
    l.info('Merging with $otherJson');
    final self = (await _taskListCrdt);
    final other = MapCrdt<String, Task>.fromJson(
      jsonDecode(otherJson),
      valueDecode: (valueJson) => Task.fromJson(valueJson),
    );
    self.merge(other);
    l.info('Merge result ${self.toJson()}');
    await _store(self);
  }

  Future<MapCrdt<String, Task>> get _taskListCrdt async => await _fromJson(
        await _keyValueRepository.get<String>(_crdtTaskListKey) ?? '{}',
      );

  Future<MapCrdt<String, Task>> _fromJson(String source) async {
    final Map<String, dynamic> jsonMap = jsonDecode(source);
    final peerId = await _identityService.peerId;
    if (jsonMap.isEmpty) return MapCrdt(peerId);
    final crdt = MapCrdt<String, Task>.fromJson(
      jsonMap,
      valueDecode: (value) => Task.fromJson(value),
    );
    if (crdt.node != peerId) {
      l.severe(
        'Got invalid node id when reading task list from disk (disk != peerId): "${crdt.node}" != "$peerId"',
      );
      if (crdt.hasNode(peerId)) {
        l.severe(
          'A node with this peer id already exists. Changing disk node id (could indicate another device is using the same node id which is VERY unlikely and breaks the algorithm)',
        );
      } else {
        l.warning(
          'Changing disk node id. The old node id might be dead from now on',
        );
        crdt.addNode(peerId);
      }

      return MapCrdt(
        peerId,
        nodes: crdt.nodes.toSet(),
        vectorClock: crdt.vectorClock,
        records: crdt.records,
        validateRecords: false,
      );
    }

    return crdt;
  }
}

class TaskRecord {
  final Task task;
  final String peerId;
  final DateTime timestamp;

  const TaskRecord(this.task, this.peerId, this.timestamp);
}
