import 'package:json_annotation/json_annotation.dart';
import 'package:p2p_task/utils/data_model.dart';

part 'peer_info.g.dart';

@JsonSerializable()
class PeerLocation {
  String uriStr;
  String? networkName;

  PeerLocation(this.uriStr, [this.networkName]);

  factory PeerLocation.fromJson(Map<String, dynamic> json) =>
      _$PeerLocationFromJson(json);

  Map<String, dynamic> toJson() => _$PeerLocationToJson(this);

  Uri get uri => Uri.parse(uriStr);

  @override
  String toString() {
    return networkName == null ? uriStr : '$networkName@$uriStr';
  }
}

@JsonSerializable(explicitToJson: true)
class PeerInfo implements DataModel {
  String? id;
  String name = '';
  List<PeerLocation> locations = [];

  PeerInfo();

  factory PeerInfo.fromJson(Map<String, dynamic> json) =>
      _$PeerInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PeerInfoToJson(this);

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
    return '[${locations.join(',')}]' +
        (buffer.isEmpty ? '' : ' (${buffer.toString()})');
  }
}
