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

  const TaskListActivity(
    String peerId,
    DateTime timestamp,
    String id,
    this.taskList,
  ) : super(peerId, timestamp, id);

  bool get isDeleted => taskList == null;

  @override
  String get description {
    if (isDeleted) return 'Task List deleted';

    return 'Task List created: "${taskList!.title}"';
  }
}

class TaskActivity extends ActivityRecord {
  final Task? task;
  final String taskListId;
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
