import 'package:json_annotation/json_annotation.dart';

part 'task.g.dart';

/// A task allows a user to keep track of their ToDos.
///
/// A task is stored with a task list ([taskListID]). It has a [title], which
/// summarizes the task and an optional [description], used to describe the task
/// in more detail.
///
/// If a user is done with a task, they mark it as [completed]. Also [isFlagged]
/// indicates whether a task is important or not. A [due] date may be set.
/// It can also be tracked when the [dueNotification] should occur.
@JsonSerializable()
class Task {
  String? id;
  String taskListID;
  String title;
  String? description;
  bool completed;
  bool isFlagged;
  DateTime? due;
  DateTime? dueNotification;

  Task({
    this.id,
    required this.title,
    required this.taskListID,
    this.description,
    this.completed = false,
    this.due,
    this.dueNotification,
    this.isFlagged = false,
  });

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  Map<String, dynamic> toJson() => _$TaskToJson(this);

  @override
  int get hashCode => id == null ? title.hashCode : id.hashCode;

  @override
  bool operator ==(Object other) {
    if (!(other is Task)) return false;

    return other.id == id &&
        other.taskListID == other.taskListID &&
        other.title == title &&
        other.completed == completed &&
        other.description == description &&
        other.due == due &&
        other.dueNotification == dueNotification &&
        other.isFlagged == isFlagged;
  }
}
