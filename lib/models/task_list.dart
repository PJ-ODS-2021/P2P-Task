import 'package:json_annotation/json_annotation.dart';
import 'package:p2p_task/models/task.dart';

part 'task_list.g.dart';

@JsonSerializable(explicitToJson: true)
class TaskList {
  final String title;
  final List<Task> elements;

  TaskList(this.title, this.elements);

  factory TaskList.fromJson(Map<String, dynamic> json) =>
      _$TaskListFromJson(json);

  Map<String, dynamic> toJson() => _$TaskListToJson(this);
}
