import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'task.g.dart';

@JsonSerializable()
class Task {
  final String id;
  String title;
  bool completed;
  String? description;
  DateTime? due;
  DateTime? dueNotification;
  String? priority;

  Task(
      {String? id,
      required this.title,
      this.description,
      this.completed = false,
      this.due,
      this.dueNotification,
      this.priority})
      : id = id ?? Uuid().v4();

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  Map<String, dynamic> toJson() => _$TaskToJson(this);
}
