import 'package:json_annotation/json_annotation.dart';
import 'package:p2p_task/utils/serializable.dart';

part 'debug_message.g.dart';

@JsonSerializable()
class DebugMessage extends Serializable {
  String value;
  String publicKey;

  DebugMessage(this.value, this.publicKey);

  factory DebugMessage.fromJson(Map<String, dynamic> json) =>
      _$DebugMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$DebugMessageToJson(this);
}
