import 'package:json_annotation/json_annotation.dart';
import 'dart:typed_data';

class Uint8ListConverter implements JsonConverter<Uint8List, List<dynamic>> {
  const Uint8ListConverter();

  @override
  Uint8List fromJson(List<dynamic> jsonDyn) {
    var json = jsonDyn.cast<int>();

    return Uint8List.fromList(
      json,
    );
  }

  @override
  List<int> toJson(Uint8List object) {
    return object.toList();
  }
}
