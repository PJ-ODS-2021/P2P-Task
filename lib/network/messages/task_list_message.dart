import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:p2p_task/network/messages/converter.dart';
import 'package:p2p_task/utils/serializable.dart';

part 'task_list_message.g.dart';

@JsonSerializable()
class TaskListMessage implements Serializable {
  String taskListCrdtJson;
  bool requestReply;
  String peerId;

  @Uint8ListConverter()
  Uint8List signature;

  TaskListMessage(
    this.taskListCrdtJson,
    this.peerId,
    this.signature, {
    this.requestReply = false,
  });

  factory TaskListMessage.fromJson(Map<String, dynamic> json) =>
      _$TaskListMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TaskListMessageToJson(this);
}
