import 'dart:convert';

import 'package:crdt/crdt.dart';
import 'package:flutter/cupertino.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:p2p_task/utils/log_mixin.dart';
import 'package:uuid/uuid.dart';

class TaskListService extends ChangeNotifier with LogMixin {
  final String _crdtTaskListKey = 'crdtTaskList';

  KeyValueRepository _keyValueRepository;
  IdentityService _identityService;
  SyncService _syncService;

  TaskListService(KeyValueRepository keyValueRepository,
      IdentityService identityService, SyncService syncService)
      : this._keyValueRepository = keyValueRepository,
        this._identityService = identityService,
        this._syncService = syncService;

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
    notifyListeners();
    await _syncService.run();
  }

  Future<int> count() async {
    return (await tasks).length;
  }

  Future _store(MapCrdt<String, Task> update) async {
    await _keyValueRepository.put(_crdtTaskListKey, update.toJson());
    notifyListeners();
  }

  Future<String> crdtToJson() async {
    return (await _taskListCrdt).toJson();
  }

  Future mergeCrdtJson(String crdtJson) async {
    l.info('Merging with $crdtJson');
    final update = (await _taskListCrdt)
      ..mergeJson(crdtJson, valueDecoder: (key, value) => Task.fromJson(value));
    l.info('Merge result ${update.toJson()}');
    await _store(update);
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

  @override
  // ignore: must_call_super
  void dispose() {}
}
