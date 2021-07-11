import 'package:json_annotation/json_annotation.dart';
import 'package:p2p_task/utils/serializable.dart';
import 'dart:typed_data';
import 'package:p2p_task/network/messages/converter.dart';

part 'introduction_message.g.dart';

@JsonSerializable()
class IntroductionMessage extends Serializable {
  String peerId;
  String name;
  String ip;
  int port;
  String publicKeyPem;
  bool requestReply;

  @Uint8ListConverter()
  Uint8List signature;

  IntroductionMessage({
    required this.peerId,
    required this.name,
    required this.ip,
    required this.port,
    required this.publicKeyPem,
    required this.signature,
    this.requestReply = false,
  });

  factory IntroductionMessage.fromJson(Map<String, dynamic> json) =>
      _$IntroductionMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$IntroductionMessageToJson(this);
}
