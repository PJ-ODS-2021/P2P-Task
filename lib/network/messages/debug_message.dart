import 'package:json_annotation/json_annotation.dart';
import 'package:p2p_task/utils/serializable.dart';

part 'debug_message.g.dart';

@JsonSerializable()
class DebugMessage implements Serializable {
  String value;

  DebugMessage(this.value);

  factory DebugMessage.fromJson(Map<String, dynamic> json) =>
      _$DebugMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$DebugMessageToJson(this);
}
