import 'dart:collection';
import 'package:flutter/cupertino.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/models/task_list.dart';

class TaskListService extends ChangeNotifier {
  TaskList _taskList = TaskList('List', []);

  TaskListService();

  UnmodifiableListView<Task> get tasks => UnmodifiableListView(_taskList.elements);

  void upsert(Task task) {
    int index = _taskList.elements.indexWhere((element) => element.id == task.id);
    if (index > -1) {
      _taskList.elements.removeAt(index);
      _taskList.elements.insert(index, task);
    } else {
      _taskList.elements.add(task);
    }
    notifyListeners();
  }

  void remove(Task task) {
    _taskList.elements.remove(task);
    notifyListeners();
  }
}
