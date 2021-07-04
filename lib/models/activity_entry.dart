/// Describes changes to Tasks and TaskLists.
///
/// The peer responsible for the change is stored in [peerId].
/// Each change has a [type] (i.e. created, updated, deleted) and a [timestamp].
/// [taskID] refers to the task which was changed.
/// The [taskListID] refers to the task list that got changed
/// or the task list of the changed task.
/// If [name] is set, is contains the name of the task or task list.
///
/// If the activity is only about a task list, [taskID] will be null.
class ActivityEntry {
  final String peerID;
  final ActivityType type;
  final DateTime timestamp;
  final String name;
  final String? taskID;
  final String? taskListID;

  ActivityEntry({
    required this.peerID,
    required this.type,
    required this.timestamp,
    this.name = '',
    this.taskID,
    this.taskListID,
  });

  bool get isTaskActivity => taskID != null;
  bool get isTaskListActivity => taskID == null;
}

enum ActivityType {
  Created,
  Updated,
  Deleted,
}
