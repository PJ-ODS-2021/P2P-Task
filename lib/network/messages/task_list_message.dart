import 'package:json_annotation/json_annotation.dart';
import 'package:p2p_task/utils/serializable.dart';
import 'package:pointycastle/export.dart';

part 'task_list_message.g.dart';

@JsonSerializable()
class TaskListMessage extends Serializable {
  String taskListCrdtJson;
  bool requestReply;
  String? publicKeyPem;

  TaskListMessage(this.taskListCrdtJson,
      {this.requestReply = false, this.publicKeyPem});

  factory TaskListMessage.fromJson(Map<String, dynamic> json) =>
      _$TaskListMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TaskListMessageToJson(this);
}
