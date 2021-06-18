import 'package:uuid/uuid.dart';

/// Describes changes to Tasks and TaskLists.
///
/// Each change is described by an [event] e.g. Task Created,
/// Description Updated, or Task List created.
/// [taskID] refers to the task which was changed. The [taskListID] refers to
/// the task list that got changed. Only one of the two should be present!
///
/// If the change occurred on a different peer and was registered after sync,
/// the [peerInfoID] will be set.
class ActivityEntry {
  String? id;
  DateTime? timestamp;
  final String event;
  final String device;
  final String? peerInfoID;
  final String? taskID;
  final String? taskListID;
  ActivityEntry({
    this.id,
    this.timestamp,
    this.event = '',
    this.device = '',
    this.peerInfoID,
    this.taskID,
    this.taskListID,
  }) {
    id ??= Uuid().v4();
    timestamp ??= DateTime.now();
  }
}
