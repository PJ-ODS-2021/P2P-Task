import 'package:json_annotation/json_annotation.dart';
import 'package:p2p_task/utils/data_model.dart';

part 'peer_info.g.dart';

@JsonSerializable()
class PeerLocation {
  final String uriStr;
  final String? networkName;

  const PeerLocation(this.uriStr, [this.networkName]);

  factory PeerLocation.fromJson(Map<String, dynamic> json) =>
      _$PeerLocationFromJson(json);

  Map<String, dynamic> toJson() => _$PeerLocationToJson(this);

  Uri get uri => Uri.parse(uriStr);

  @override
  String toString() {
    return networkName == null ? uriStr : '$networkName@$uriStr';
  }

  @override
  int get hashCode => uriStr.hashCode;

  @override
  bool operator ==(Object other) {
    if (!(other is PeerLocation)) return false;
    return other.uriStr == uriStr && other.networkName == networkName;
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

  void addPeerLocation(PeerLocation location) {
    if (!locations.contains(location)) locations.add(location);
  }

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
