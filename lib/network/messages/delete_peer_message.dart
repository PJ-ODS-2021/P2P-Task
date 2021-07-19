import 'package:json_annotation/json_annotation.dart';
import 'package:p2p_task/utils/serializable.dart';
import 'dart:typed_data';
import 'package:p2p_task/network/messages/converter.dart';

part 'delete_peer_message.g.dart';

@JsonSerializable()
class DeletePeerMessage implements Serializable {
  String peerID;

  @Uint8ListConverter()
  Uint8List signature;

  DeletePeerMessage(this.peerID, this.signature);

  factory DeletePeerMessage.fromJson(Map<String, dynamic> json) =>
      _$DeletePeerMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$DeletePeerMessageToJson(this);
}
