import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/models/task_list.dart';

abstract class ActivityRecord {
  final String peerId;
  final DateTime timestamp;
  final String id;

  const ActivityRecord(this.peerId, this.timestamp, this.id);

  String get description;
}

class TaskListActivity extends ActivityRecord {
  /// The elements in the task list will always be empty
  final TaskList? taskList;

  /// False if this activity describes a change to the top-level task list node.
  /// True if this activity describes a change to a property of the task list (e.g. title).
  /// Does not indicate if a task in a task list has been created/update/deleted.
  final bool isPropertyUpdate;

  const TaskListActivity(
    String peerId,
    DateTime timestamp,
    String id,
    this.taskList,
    this.isPropertyUpdate,
  ) : super(peerId, timestamp, id);

  bool get isDeleted => taskList == null;

  @override
  String get description {
    if (isDeleted) return 'Task List deleted';

    return isPropertyUpdate
        ? 'Task List updated: "${taskList!.title}"'
        : 'Task List created: "${taskList!.title}"';
  }
}

class TaskActivity extends ActivityRecord {
  final Task? task;
  final String taskListId;

  /// False if this activity describes a change to the top-level task node.
  /// True if this activity describes a change to a sub-node in the task (e.g. title, description).
  final bool isRecursiveUpdate;

  const TaskActivity(
    String peerId,
    DateTime timestamp,
    String id,
    this.task,
    this.taskListId,
    this.isRecursiveUpdate,
  ) : super(peerId, timestamp, id);

  bool get isDeleted => task == null;

  @override
  String get description {
    if (isDeleted) return 'Task deleted';

    return isRecursiveUpdate
        ? 'Task updated: "${task!.title}"'
        : 'Task created: "${task!.title}"';
  }
}
