import 'package:json_annotation/json_annotation.dart';
import 'package:p2p_task/models/task.dart';

part 'task_list.g.dart';

/// A collection of multiple tasks.
///
/// Users give their lists a [title] upon creation. A task can be added to or
/// removed from the [elements] list of a task list.
///
/// When users share a task list with another peer, the [elements] in the list
/// are exchanged between the peers.
///
/// Here, the [id] is used to identify task lists throughout peers.
@JsonSerializable(explicitToJson: true)
class TaskList {
  String? id;
  bool isShared;
  String title;
  SortOption sortBy;
  final List<Task> elements;

  TaskList({
    this.id,
    required this.title,
    this.elements = const [],
    this.isShared = false,
    this.sortBy = SortOption.Created,
  });

  factory TaskList.fromJson(Map<String, dynamic> json) =>
      _$TaskListFromJson(json);

  Map<String, dynamic> toJson() => _$TaskListToJson(this);

  @override
  int get hashCode => id == null ? title.hashCode : id.hashCode;

  @override
  bool operator ==(Object other) {
    if (!(other is TaskList)) return false;

    return other.id == id && other.title == title;
  }
}
