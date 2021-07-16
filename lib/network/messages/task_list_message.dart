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

  /// If not null, the message will be forwarded to known peers not in this list
  Set<String>? traversedPeerIds;

  TaskListMessage(
    this.taskListCrdtJson,
    this.peerId,
    this.signature, {
    this.requestReply = false,
    this.traversedPeerIds,
  });

  factory TaskListMessage.fromJson(Map<String, dynamic> json) =>
      _$TaskListMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TaskListMessageToJson(this);
}
