import 'package:p2p_task/network/messages/packet.dart';
import 'package:p2p_task/utils/serializable.dart';

typedef JsonDecodeFunction = Object? Function(Map<String, dynamic> json);

class _TypeInfo {
  String typename;
  JsonDecodeFunction fromJsonFunc;

  _TypeInfo(this.typename, this.fromJsonFunc);
}

class PacketHandler<T> {
  static const version = '0.1.0';

  void Function(Packet, T)? defaultCallback;
  final Map<String, void Function(Packet, T)> _callbacks = {};
  final Map<Type, _TypeInfo> _typenames = {};

  Packet toPacket<S extends Serializable>(S value) {
    final typename = _getTypeInfo(S).typename;

    return Packet(typename, version: version, object: value.toJson());
  }

  void invokeCallback(Packet packet, T source) {
    var callback = _callbacks[packet.typename];
    if (callback == null) {
      if (defaultCallback != null) defaultCallback!(packet, source);
    } else {
      callback(packet, source);
    }
  }

  void registerCallback<E>(
    Function(E, T source) callback,
  ) {
    final typeInfo = _getTypeInfo(E);
    assert(!_callbacks.containsKey(typeInfo.typename),
        'a callback for this typename already exists');
    _callbacks[typeInfo.typename] = (packet, client) {
      final obj = typeInfo.fromJsonFunc(packet.object);
      if (obj != null) callback(obj as E, client);
    };
  }

  void registerTypename<E>(
    String typename,
    E Function(Map<String, dynamic> json) jsonDecodeFunction,
  ) {
    assert(!_typenames.containsKey(E), 'typename already exists');
    _typenames[E] = _TypeInfo(typename, jsonDecodeFunction);
  }

  void clearTypenames() {
    _typenames.clear();
  }

  void clearCallbacks() {
    _callbacks.clear();
    defaultCallback = null;
  }

  void clear() {
    clearTypenames();
    clearCallbacks();
  }

  _TypeInfo _getTypeInfo(Type type) {
    final info = _typenames[type];
    if (info != null) return info;
    throw Exception('could not get typename for class $type');
  }
}
