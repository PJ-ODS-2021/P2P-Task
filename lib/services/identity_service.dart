import 'package:flutter/foundation.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:p2p_task/utils/log_mixin.dart';
import 'package:uuid/uuid.dart';

class IdentityService extends ChangeNotifier with LogMixin {
  static const String _PEER_ID_KEY = 'peerId';
  static const String _NAME_KEY = 'name';
  static const String _IP_KEY = 'ip';
  static const String _PORT_KEY = 'port';

  KeyValueRepository _repository;

  IdentityService(KeyValueRepository repository)
      : this._repository = repository;

  Future<String> get peerId async {
    var peerId = await _repository.get<String>(_PEER_ID_KEY);
    if (peerId != null) {
      l.info('Returning already present peer id "$peerId".');
      return peerId;
    }
    l.info('No peer id, creating one...');
    peerId = await _repository.put(_PEER_ID_KEY, Uuid().v4());
    l.info('Peer id "$peerId" created and stored.');
    notifyListeners();
    return peerId!;
  }

  Future<String> get name async =>
      (await _repository.get<String>(_NAME_KEY)) ?? 'Clementine';

  Future setName(String name) async {
    final updatedName = await _repository.put(_NAME_KEY, name);
    notifyListeners();
    return updatedName;
  }

  Future<String?> get ip async => await _repository.get<String>(_IP_KEY);

  Future setIp(String ip) async {
    final updatedIp = await _repository.put(_IP_KEY, ip);
    notifyListeners();
    return updatedIp;
  }

  Future<int> get port async =>
      (await _repository.get<int>(_PORT_KEY)) ?? 58241;

  Future<int> setPort(int port) async {
    if (port < 0 || port > 65355)
      throw UnsupportedError('Port needs to be in ranges 0 - 65355.');
    final updatedPort = await _repository.put(_PORT_KEY, port);
    notifyListeners();
    return updatedPort;
  }
}
