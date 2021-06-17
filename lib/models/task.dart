import 'package:json_annotation/json_annotation.dart';

part 'task.g.dart';

@JsonSerializable()
class Task {
  String? id;
  String title;
  bool completed;
  String? description;
  DateTime? due;
  DateTime? dueNotification;
  String? priority;

  Task(
      {this.id,
      required this.title,
      this.description,
      this.completed = false,
      this.due,
      this.dueNotification,
      this.priority});

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  Map<String, dynamic> toJson() => _$TaskToJson(this);

  @override
  int get hashCode => id == null ? title.hashCode : id.hashCode;

  @override
  bool operator ==(Object other) {
    if (!(other is Task)) return false;
    return other.id == id &&
        other.title == title &&
        other.completed == completed &&
        other.description == description &&
        other.due == due &&
        other.dueNotification == dueNotification &&
        other.priority == priority;
  }
}
