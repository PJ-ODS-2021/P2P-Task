import 'package:json_annotation/json_annotation.dart';
import 'package:p2p_task/models/task.dart';

part 'task_list.g.dart';

@JsonSerializable(explicitToJson: true)
class TaskList {
  String? id;
  bool isShared;
  String title;
  final List<Task>? elements;

  TaskList(
      {this.id, required this.title, this.elements, this.isShared = false});

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
