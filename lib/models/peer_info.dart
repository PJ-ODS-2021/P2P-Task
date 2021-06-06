import 'package:json_annotation/json_annotation.dart';
import 'package:p2p_task/utils/data_model.dart';

part 'peer_info.g.dart';

@JsonSerializable()
class PeerInfo implements DataModel {
  String? id;
  String name = '';
  String networkName = '';
  String ip = '';
  int port = -1;

  PeerInfo();

  factory PeerInfo.fromJson(Map<String, dynamic> json) =>
      _$PeerInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PeerInfoToJson(this);

  bool get isValid => ip.isNotEmpty && port > 0;
  Uri get websocketUri => Uri.parse('ws://$ip:$port');

  @override
  String toString() {
    final buffer = StringBuffer();
    final addProperty = (String name, String? property) {
      if (property == null || property.isEmpty) return;
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write('$name: "$property"');
    };
    addProperty('id', id);
    addProperty('name', name);
    addProperty('networkName', networkName);
    return '$ip:$port' + (buffer.isEmpty ? '' : ' (${buffer.toString()})');
  }
}
