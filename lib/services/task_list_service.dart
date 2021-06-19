import 'dart:convert';

import 'package:crdt/crdt.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/services/change_callback_provider.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:p2p_task/utils/log_mixin.dart';
import 'package:uuid/uuid.dart';

enum Filter {
  Title,
  Priority,
  Status,
  DueDate,
  Default,
}

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

  Future<List<Task>> get tasks async {
    return (await _taskListCrdt).values;
  }

  Future<List<Task>> getTasksByListID(String taskListID, Filter filter) async {
    List<Task> tasks = [];

    for (var i = 0; i < (await _taskListCrdt).values.length; i++) {
      if ((await _taskListCrdt).values[i].taskListID == taskListID) {
        tasks.add((await _taskListCrdt).values[i]);
      }
    }

    switch (filter) {
      case Filter.Title:
        tasks.sort((a, b) => a.title.toString().compareTo(b.title.toString()));
        break;
      case Filter.Priority:
        tasks.sort((a, b) {
          if (b.isFlagged) {
            return 1;
          }
          return -1;
        });
        break;
      case Filter.Status:
        tasks.sort((a, b) {
          if (b.completed) {
            return -1;
          }
          return 1;
        });
        break;
      case Filter.DueDate:
        tasks.sort((a, b) {
          if (b.due == null) {
            return -1;
          }
          if (a.due == null) {
            return 1;
          }
          return a.due!.compareTo(b.due!);
        });
        break;
      default:
        tasks.sort((a, b) {
          if (b.completed) {
            return -1;
          }
          return 1;
        });
        break;
    }

    return tasks;
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

  Future removeByListID(String taskListID) async {
    for (var i = 0; i < (await _taskListCrdt).values.length; i++) {
      if ((await _taskListCrdt).values[i].taskListID == taskListID) {
        remove((await _taskListCrdt).values[i]);
      }
    }
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
    // Remove records from this node from the task list. This could also be done in the sender.
    other.removeWhere((key, value) => value.hlc.nodeId == self.nodeId);
    final update = self..merge(other);
    l.info('Merge result ${update.toJson()}');
    await _store(update);
  }

  Future<MapCrdt<String, Task>> get _taskListCrdt async => await _fromJson(
        await _keyValueRepository.get<String>(_crdtTaskListKey) ?? '{}',
      );

  Future<MapCrdt<String, Task>> _fromJson(String json) async {
    final Map<String, dynamic> map = jsonDecode(json);
    final keys = map.keys.toList();
    final recordMap = <String, Record<Task>>{};
    for (var i = 0; i < map.length; ++i) {
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
