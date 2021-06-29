import 'dart:convert';

import 'package:crdt/crdt.dart';
import 'package:p2p_task/models/task_list.dart';
import 'package:p2p_task/services/change_callback_provider.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:p2p_task/utils/log_mixin.dart';
import 'package:uuid/uuid.dart';

class TaskListsService with LogMixin, ChangeCallbackProvider {
  final String _crdtTaskLisstKey = 'crdtTaskLists';

  final KeyValueRepository _keyValueRepository;
  final IdentityService _identityService;
  final SyncService _syncService;

  bool isShared = false;

  TaskListsService(
    this._keyValueRepository,
    this._identityService,
    this._syncService,
  );

  Future<List<TaskList>> get lists async {
    var lists = <TaskList>[];

    for (var i = 0; i < (await _taskListsCrdt).values.length; i++) {
      lists.add((await _taskListsCrdt).values[i]);
    }

    lists.sort((a, b) => a.title.toString().compareTo(b.title.toString()));

    return lists;
  }

  Future upsert(TaskList taskList) async {
    if (!taskList.isShared) {
      taskList.isShared = isShared;
    }

    l.info('Upsert taskList ${taskList.toJson()}');
    final id = Uuid().v4();
    final update = (await _taskListsCrdt)
      ..put(taskList.id ?? id, taskList..id = (taskList.id ?? id));
    await _store(update);
    await _syncService.run(runOnSyncOnUpdate: true);
  }

  Future remove(TaskList taskList) async {
    final update = (await _taskListsCrdt)..delete(taskList.id!);
    await _store(update);
    await _syncService.run(runOnSyncOnUpdate: true);
  }

  Future delete() async {
    await _keyValueRepository.purge(key: _crdtTaskLisstKey);
    invokeChangeCallback();
    await _syncService.run(runOnSyncOnUpdate: true);
  }

  Future<int> count() async {
    return (await lists).length;
  }

  Future<void> _store(MapCrdt<String, TaskList> update) async {
    await _keyValueRepository.put(_crdtTaskLisstKey, update.toJson());
    invokeChangeCallback();
    l.info('notifying task lists change');
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

    if (!isShared) {
      isShared = true;
      for (var i = 0; i < (await _taskListsCrdt).values.length; i++) {
        await upsert((await _taskListsCrdt).values[i]);
      }
    }
  }

  Future<MapCrdt<String, TaskList>> get _taskListsCrdt async => await _fromJson(
        await _keyValueRepository.get<String>(_crdtTaskLisstKey) ?? '{}',
      );

  Future<MapCrdt<String, TaskList>> _fromJson(String json) async {
    final Map<String, dynamic> map = jsonDecode(json);
    final keys = map.keys.toList();
    final recordMap = <String, Record<TaskList>>{};
    for (var i = 0; i < map.length; ++i) {
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
}
