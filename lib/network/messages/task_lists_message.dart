import 'package:json_annotation/json_annotation.dart';
import 'package:p2p_task/utils/serializable.dart';
import 'package:pointycastle/pointycastle.dart';

part 'task_lists_message.g.dart';

@JsonSerializable()
class TaskListsMessage extends Serializable {
  String taskListsCrdtJson;
  bool requestReply;
  String? publicKeyPem;

  TaskListsMessage(this.taskListsCrdtJson,
      {this.requestReply = false, this.publicKeyPem});

  factory TaskListsMessage.fromJson(Map<String, dynamic> json) =>
      _$TaskListsMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TaskListsMessageToJson(this);
}
