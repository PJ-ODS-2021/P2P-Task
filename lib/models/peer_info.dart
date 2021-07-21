import 'package:collection/collection.dart';
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
  bool operator ==(Object other) {
    return other is PeerLocation &&
        other.uriStr == uriStr &&
        other.networkName == networkName;
  }

  @override
  String toString() {
    return networkName == null ? uriStr : '$networkName@$uriStr';
  }
}

// Status created indicates that the key exchange has started, but not finished yet.
// It might have failed because the sever was off.
// Once it is successfull, the status will be set to active.
enum Status { created, active }

@JsonSerializable(explicitToJson: true)
class PeerInfo implements DataModel {
  @override
  String? id;
  String name;
  Status status;
  List<PeerLocation> locations;
  String publicKeyPem;

  PeerInfo({
    String? id,
    required this.name,
    required this.status,
    required this.publicKeyPem,
    required this.locations,
  }) : id = id;

  factory PeerInfo.fromJson(Map<String, dynamic> json) =>
      _$PeerInfoFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$PeerInfoToJson(this);

  PeerInfo copyWith({
    String? name,
    List<PeerLocation>? locations,
    String? publicKeyPem,
    Status? status,
  }) =>
      PeerInfo(
        id: id,
        name: name ?? this.name,
        status: status ?? this.status,
        publicKeyPem: publicKeyPem ?? this.publicKeyPem,
        locations: locations ?? this.locations,
      );

  void addPeerLocation(PeerLocation location) {
    if (!locations.contains(location)) locations.add(location);
  }

  @override
  bool operator ==(Object other) {
    return other is PeerInfo &&
        other.id == id &&
        other.name == name &&
        other.status == status &&
        ListEquality().equals(other.locations, locations) &&
        other.publicKeyPem == publicKeyPem;
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
    addProperty('status', status.toString());
    addProperty('public_key_pem', publicKeyPem);

    return '[${locations.join(',')}]' +
        (buffer.isEmpty ? '' : ' (${buffer.toString()})');
  }
}

extension Value on Status {
  String get value => toString().split('.').last;
}
