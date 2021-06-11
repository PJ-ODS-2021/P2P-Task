import 'package:p2p_task/network/packet.dart';
import 'package:p2p_task/network/serializable.dart';

typedef PacketCallback = void Function(Packet);
typedef JsonDecodeFunction = Object? Function(Map<String, dynamic> json);

class _TypeInfo {
  String typename;
  JsonDecodeFunction fromJsonFunc;

  _TypeInfo(this.typename, this.fromJsonFunc);
}

class PacketHandler {
  static const version = '0.1.0';

  PacketCallback defaultCallback =
      (packet) => print('[WARNING] no callback for "$packet"');
  final Map<String, PacketCallback> _callbacks = {};
  final Map<Type, _TypeInfo> _typenames = {};

  Packet toPacket<T extends Serializable>(T value) {
    final typename = _getTypeInfo(T).typename;

    return Packet(typename, version: version, object: value.toJson());
  }

  void invokeCallback(Packet packet) {
    var callback = _callbacks[packet.typename];
    if (callback == null) {
      defaultCallback(packet);
    } else {
      callback(packet);
    }
  }

  void registerCallback<T>(Function(T) callback) {
    final typeInfo = _getTypeInfo(T);
    assert(!_callbacks.containsKey(typeInfo.typename),
        'a callback for this typename already exists');
    _callbacks[typeInfo.typename] = (packet) {
      final obj = typeInfo.fromJsonFunc(packet.object);
      if (obj != null) callback(obj as T);
    };
  }

  void registerTypename<T>(
    String typename,
    T Function(Map<String, dynamic> json) jsonDecodeFunction,
  ) {
    assert(!_typenames.containsKey(T), 'typename already exists');
    _typenames[T] = _TypeInfo(typename, jsonDecodeFunction);
  }

  _TypeInfo _getTypeInfo(Type type) {
    final info = _typenames[type];
    if (info != null) return info;
    throw Exception('could not get typename for class $type');
  }
}
