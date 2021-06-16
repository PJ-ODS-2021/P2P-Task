import 'dart:convert';

import 'package:crdt/crdt.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/services/change_callback_provider.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:p2p_task/utils/log_mixin.dart';
import 'package:uuid/uuid.dart';

class TaskListService with LogMixin, ChangeCallbackProvider {
  final String _crdtTaskListKey = 'crdtTaskList';

  KeyValueRepository _keyValueRepository;
  IdentityService _identityService;
  SyncService _syncService;

  TaskListService(
      this._keyValueRepository, this._identityService, this._syncService);

  Future<List<Task>> get tasks async {
    return (await _taskListCrdt).values;
  }

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
    await _keyValueRepository.put(_crdtTaskListKey, update.toJson());
    invokeChangeCallback();
    l.info('notifying task list change');
  }

  Future<String> crdtToJson() async {
    return (await _taskListCrdt).toJson();
  }

  Future mergeCrdtJson(String crdtJson) async {
    l.info('Merging with $crdtJson');
    final self = (await _taskListCrdt);
    final other = CrdtJson.decode<String, Task>(
      crdtJson,
      self.canonicalTime,
      valueDecoder: (key, value) => Task.fromJson(value),
    );

    _mergeCrdt(self, other);
    l.info('Merge result ${self.toJson()}');
    await _store(self);
  }

  void _mergeCrdt(
      MapCrdt<String, Task> crdt, Map<String, Record<Task>> remoteRecords) {
    // Remove records from this node from the task list. This could also be done in the sender.
    remoteRecords.removeWhere((key, value) => value.hlc.nodeId == crdt.nodeId);
    try {
      crdt.merge(remoteRecords);
    } on ClockDriftException {
      _fixClockDrift(remoteRecords);
      _mergeCrdt(crdt, remoteRecords);
    }
  }

  void _fixClockDrift(Map<String, Record<Task>> records) {
    const maxClockDrift = 60000; // 1min in ms (hard-coded in the crdt library)
    final now = DateTime.now().millisecondsSinceEpoch;
    final maxMillis = now + maxClockDrift;
    List<_Tuple<String, Record<Task>>> invalidRecords = [];
    records.forEach((key, value) {
      if (value.hlc.millis > maxMillis) invalidRecords.add(_Tuple(key, value));
    });
    invalidRecords.sort((a, b) => a.second.hlc.compareTo(b.second.hlc));
    var counter = 0;
    invalidRecords.forEach((tuple) {
      final newHlc = Hlc(maxMillis, counter++, tuple.second.hlc.nodeId);
      records[tuple.first] =
          Record(newHlc, tuple.second.value, tuple.second.modified);
    });
  }

  Future<MapCrdt<String, Task>> get _taskListCrdt async => await _fromJson(
      await _keyValueRepository.get<String>(_crdtTaskListKey) ?? '{}');

  Future<MapCrdt<String, Task>> _fromJson(String json) async {
    final Map<String, dynamic> map = jsonDecode(json);
    final keys = map.keys.toList();
    final recordMap = Map<String, Record<Task>>();
    for (int i = 0; i < map.length; ++i) {
      recordMap.putIfAbsent(
        keys[i],
        () => Record(
          Hlc.parse(map[keys[i]]['hlc']),
          map[keys[i]]['value'] == null
              ? null
              : Task.fromJson(map[keys[i]]['value']),
          Hlc.parse(map[keys[i]]['modified'] ?? map[keys[i]]['hlc']),
        ),
      );
    }
    return MapCrdt(await _identityService.peerId, recordMap);
  }
}

class _Tuple<T, U> {
  final T first;
  final U second;

  const _Tuple(this.first, this.second);
}
