import 'dart:convert';

import 'package:crdt/crdt.dart';
import 'package:flutter/cupertino.dart';
import 'package:p2p_task/models/task_list.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:p2p_task/utils/log_mixin.dart';
import 'package:uuid/uuid.dart';

class TaskListsService extends ChangeNotifier with LogMixin {
  final String _crdtTaskLisstKey = 'crdtTaskLists';
  KeyValueRepository _keyValueRepository;
  IdentityService _identityService;
  SyncService _syncService;

  // stupid
  bool isShared = false;

  TaskListsService(KeyValueRepository keyValueRepository,
      IdentityService identityService, SyncService syncService)
      : this._keyValueRepository = keyValueRepository,
        this._identityService = identityService,
        this._syncService = syncService;

  Future<List<TaskList>> get lists async {
    return (await _taskListsCrdt).values;
  }

  Future upsert(TaskList taskList) async {
    // stupid
    if (!taskList.isShared) {
      taskList.isShared = isShared;
    }

    l.info('Upsert taskList ${taskList.toJson()}');
    final id = Uuid().v4();
    final update = (await _taskListsCrdt)
      ..put(taskList.id ?? id, taskList..id = (taskList.id ?? id));
    await _store(update);
    await _syncService.run();
  }

  Future remove(TaskList taskList) async {
    print('removei ${taskList.title}');
    final update = (await _taskListsCrdt)..delete(taskList.id!);
    await _store(update);
    await _syncService.run();
  }

  Future delete() async {
    await _keyValueRepository.purge(key: _crdtTaskLisstKey);
    notifyListeners();
    await _syncService.run();
  }

  Future<int> count() async {
    return (await lists).length;
  }

  Future<void> _store(MapCrdt<String, TaskList> update) async {
    await _keyValueRepository.put(_crdtTaskLisstKey, update.toJson());
    notifyListeners();
    l.info('notifying task list change');
  }

  Future<String> crdtToJson() async {
    return (await _taskListsCrdt).toJson();
  }

  Future mergeCrdtJson(String crdtJson) async {
    l.info('Merging with $crdtJson');
    final self = (await _taskListsCrdt);
    final other = CrdtJson.decode<String, TaskList>(
      crdtJson,
      self.canonicalTime,
      valueDecoder: (key, value) => TaskList.fromJson(value),
    );
    // Remove records from this node from the task list. This could also be done in the sender.
    other.removeWhere((key, value) => value.hlc.nodeId == self.nodeId);
    final update = self..merge(other);
    l.info('Merge result ${update.toJson()}');
    await _store(update);

// stupid - as soon as connection is established for the first time, all lists will be shwon as shared
// also those which are not yet shared
    if (!isShared) {
      isShared = true;
      for (var i = 0; i < (await _taskListsCrdt).values.length; i++) {
        upsert((await _taskListsCrdt).values[i]);
      }
    }
  }

  Future<MapCrdt<String, TaskList>> get _taskListsCrdt async => await _fromJson(
      await _keyValueRepository.get<String>(_crdtTaskLisstKey) ?? '{}');

  Future<MapCrdt<String, TaskList>> _fromJson(String json) async {
    final Map<String, dynamic> map = jsonDecode(json);
    final keys = map.keys.toList();
    final recordMap = Map<String, Record<TaskList>>();
    for (int i = 0; i < map.length; ++i) {
      recordMap.putIfAbsent(
        keys[i],
        () => Record(
          Hlc.parse(map[keys[i]]['hlc']),
          map[keys[i]]['value'] == null
              ? null
              : TaskList.fromJson(map[keys[i]]['value']),
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
