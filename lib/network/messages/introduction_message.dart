import 'package:json_annotation/json_annotation.dart';
import 'package:p2p_task/utils/serializable.dart';

part 'introduction_message.g.dart';

@JsonSerializable()
class IntroductionMessage extends Serializable {
  String message;
  bool requestReply;

  IntroductionMessage(this.message, {this.requestReply = false});

  factory IntroductionMessage.fromJson(Map<String, dynamic> json) =>
      _$IntroductionMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$IntroductionMessageToJson(this);
}
