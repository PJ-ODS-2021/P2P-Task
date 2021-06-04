import 'package:json_annotation/json_annotation.dart';
import 'package:p2p_task/utils/data_model.dart';

part 'peer_info.g.dart';

@JsonSerializable()
class PeerInfo implements DataModel {
  String? id;
  String name = '';
  String networkName = 'Local Supermarket';
  String ip = '';
  int port = -1;

  PeerInfo();

  factory PeerInfo.fromJson(Map<String, dynamic> json) =>
      _$PeerInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PeerInfoToJson(this);
}
