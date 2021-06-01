import 'dart:collection';

import 'package:crdt/crdt.dart';
import 'package:flutter/cupertino.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/models/task_list.dart';
import 'package:uuid/uuid.dart';

class TaskListService extends ChangeNotifier {
  TaskList _taskList = TaskList('List', []);
  final _taskListCrdt = MapCrdt<String, Task>(Uuid().v4());

  TaskListService._privateConstructor();
  static final TaskListService instance = TaskListService._privateConstructor();

  UnmodifiableListView<Task> get tasks =>
      UnmodifiableListView(_taskList.elements);

  TaskList get taskList =>
      TaskList('List', UnmodifiableListView(_taskList.elements));

  void upsert(Task task) {
    int index =
        _taskList.elements.indexWhere((element) => element.id == task.id);
    if (index > -1) {
      _taskList.elements.removeAt(index);
      _taskList.elements.insert(index, task);
    } else {
      _taskList.elements.add(task);
    }
    _taskListCrdt.put(task.id, task);
    notifyListeners();
  }

  void remove(Task task) {
    _taskList.elements.remove(task);
    _taskListCrdt.delete(task.id);
    notifyListeners();
  }

  String crdtToJson() {
    return _taskListCrdt.toJson();
  }

  void mergeCrdtJson(String crdtJson) {
    print('merging with $crdtJson');
    _taskListCrdt.mergeJson(crdtJson,
        valueDecoder: (key, value) => Task.fromJson(value));
    _updateTaskListFromCrdt();
    notifyListeners();
  }

  void _updateTaskListFromCrdt() {
    // unefficient method
    print('current crdt value: ${_taskListCrdt.toJson()}');
    for (var i = 0; i < _taskList.elements.length;) {
      final task = _taskList.elements[i];
      final crdtTask = _taskListCrdt.getRecord(task.id);
      print('checking local ${task.toJson()}');
      if (crdtTask == null || crdtTask.isDeleted) {
        print('-> will be removed');
        _taskList.elements.removeAt(i);
      } else {
        print('-> will be updated');
        _taskList.elements[i++] = crdtTask.value!;
      }
    }
    _taskListCrdt.map.forEach((key, value) {
      if (!_taskList.elements.any((element) => element.id == value.id)) {
        print('adding new task ${value.toJson()}');
        _taskList.elements.add(value);
      }
    });
  }
}
