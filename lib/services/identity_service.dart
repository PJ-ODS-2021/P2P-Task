import 'package:p2p_task/services/change_callback_provider.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:p2p_task/utils/log_mixin.dart';
import 'package:uuid/uuid.dart';

class IdentityService with LogMixin, ChangeCallbackProvider {
  static const String peerIdKey = 'peerId';
  static const String peerNameKey = 'name';
  static const String peerIpKey = 'ip';
  static const String peerPortKey = 'port';

  final KeyValueRepository _repository;

  IdentityService(this._repository);

  Future<String> get peerId async {
    var peerId = await _repository.get<String>(peerIdKey);
    if (peerId != null) {
      l.info('Returning already present peer id "$peerId".');

      return peerId;
    }
    l.info('No peer id, creating one...');
    peerId = await _repository.put(peerIdKey, Uuid().v4());
    l.info('Peer id "$peerId" created and stored.');
    invokeChangeCallback();

    return peerId!;
  }

  Future<String?> get name async =>
      (await _repository.get<String>(peerNameKey));

  Future setName(String name) async {
    final updatedName = await _repository.put(peerNameKey, name);
    invokeChangeCallback();

    return updatedName;
  }

  Future<String?> get ip async => await _repository.get<String>(peerIpKey);

  Future setIp(String ip) async {
    final updatedIp = await _repository.put(peerIpKey, ip);
    invokeChangeCallback();

    return updatedIp;
  }

  Future<int> get port async =>
      (await _repository.get<int>(peerPortKey)) ?? 58241;

  Future<int> setPort(int port) async {
    if (port < 0 || port > 65355) {
      throw UnsupportedError('Port needs to be in ranges 0 - 65355.');
    }
    final updatedPort = await _repository.put(peerPortKey, port);
    invokeChangeCallback();

    return updatedPort;
  }
}
