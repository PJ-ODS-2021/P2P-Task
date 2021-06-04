import 'package:json_annotation/json_annotation.dart';
import 'package:p2p_task/utils/data_model.dart';

part 'task.g.dart';

@JsonSerializable()
class Task extends DataModel {
  String? id;
  String title = '';
  bool completed = false;
  DateTime? due;
  DateTime? dueNotification;
  String? priority;

  Task();

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  Map<String, dynamic> toJson() => _$TaskToJson(this);
}
