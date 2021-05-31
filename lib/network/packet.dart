import 'package:json_annotation/json_annotation.dart';

part 'packet.g.dart';

@JsonSerializable()
class Packet {
  final String typename;
  final String version;
  Map<String, Object?> object;

  Packet(this.typename, {this.version = '0.1.0', this.object = const {}});

  factory Packet.fromJson(Map<String, dynamic> json) => _$PacketFromJson(json);

  Map<String, dynamic> toJson() => _$PacketToJson(this);

  @override
  String toString() {
    return 'Packet{typename="$typename", version="$version"}';
  }
}
