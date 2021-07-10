import 'package:p2p_task/services/change_callback_provider.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:p2p_task/utils/log_mixin.dart';
import 'package:uuid/uuid.dart';
import 'package:p2p_task/security/key_helper.dart';
import 'package:pointycastle/export.dart';

class IdentityService with LogMixin, ChangeCallbackProvider {
  static const String peerIdKey = 'peerId';
  static const String peerNameKey = 'name';
  static const String peerIpKey = 'ip';
  static const String peerPortKey = 'port';
  static const String publicKeyKey = 'public_key';
  static const String privateKeyKey = 'private_key';
  static const int peerPortDefault = 58241;

  final KeyValueRepository _repository;

  IdentityService(this._repository);

  Future<String> get peerId async {
    var peerId = await _repository.get<String>(peerIdKey);
    if (peerId != null) {
      return peerId;
    }
    logger.info('No peer id, creating one...');
    peerId = await _repository.put(peerIdKey, Uuid().v4());
    logger.info('Peer id "$peerId" created and stored.');
    invokeChangeCallback();

    return peerId!;
  }

  Future<String> get name async =>
      (await _repository.get<String>(peerNameKey)) ?? '';

  Future setName(String name) async {
    final updatedName = await _repository.put(peerNameKey, name);
    invokeChangeCallback();

    return updatedName;
  }

  Future<String> get publicKeyPem async =>
      await _repository.get<String>(publicKeyKey) ?? '';

  Future<RSAPublicKey?> get publicKey async {
    final _publicKeyPem = await publicKeyPem;

    if (_publicKeyPem == '') {
      return null;
    }

    try {
      return KeyHelper().decodePublicKeyFromPem(_publicKeyPem);
    } on Exception catch (error) {
      logger.severe('could not parse publicKeyPem $error');
    }
  }

  Future<String> setPublicKeyPem(String publicKey) async {
    final updatedPublicKey = await _repository.put(publicKeyKey, publicKey);
    invokeChangeCallback();

    return updatedPublicKey;
  }

  Future<String> get privateKeyPem async =>
      await _repository.get<String>(privateKeyKey) ?? '';

  Future<RSAPrivateKey?> get privateKey async {
    final _privateKeyPem = await privateKeyPem;

    if (_privateKeyPem == '') {
      return null;
    }

    try {
      return KeyHelper().decodePrivateKeyFromPem(_privateKeyPem);
    } on Exception catch (error) {
      logger.severe('could not parse privateKey $error');
    }
  }

  Future<String> setPrivateKeyPem(String privateKey) async {
    final updatedPrivateKey =
        await _repository.put(privateKeyKey, privateKey, displayValue: false);
    invokeChangeCallback();

    return updatedPrivateKey;
  }

  Future<String?> get ip async => await _repository.get<String>(peerIpKey);

  Future setIp(String ip) async {
    final updatedIp = await _repository.put(peerIpKey, ip);
    invokeChangeCallback();

    return updatedIp;
  }

  Future<int> get port async =>
      (await _repository.get<int>(peerPortKey)) ?? peerPortDefault;

  Future<int> setPort(int port) async {
    if (port < 49152 || port > 65535) {
      throw UnsupportedError('Port needs to be in range of 49152 to 65535.');
    }
    final updatedPort = await _repository.put(peerPortKey, port);
    invokeChangeCallback();

    return updatedPort;
  }
}
