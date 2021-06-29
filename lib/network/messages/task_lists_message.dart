import 'package:json_annotation/json_annotation.dart';
import 'package:p2p_task/utils/serializable.dart';

part 'task_lists_message.g.dart';

@JsonSerializable()
class TaskListsMessage extends Serializable {
  String taskListsCrdtJson;
  bool requestReply;
  String publicKey;

  TaskListsMessage(this.taskListsCrdtJson, this.publicKey,
      {this.requestReply = false});

  factory TaskListsMessage.fromJson(Map<String, dynamic> json) =>
      _$TaskListsMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TaskListsMessageToJson(this);
}
