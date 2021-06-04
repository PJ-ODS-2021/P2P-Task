import 'package:p2p_task/utils/log_mixin.dart';
import 'package:sembast/sembast.dart';

class KeyValueRepository with LogMixin {
  final Database _db;
  final StoreRef<String, dynamic> _store;

  KeyValueRepository(Database database)
      : this._db = database,
        this._store = StoreRef('Settings');

  Future<dynamic> get(String key) async {
    final entry = await _store.record(key).get(_db);
    return entry;
  }

  Future<String?> getAsString(String key) async {
    final value = await get(key);
    if (value == null) return null;
    return value as String;
  }

  Future<int?> getAsInt(String key) async {
    final value = await get(key);
    if (value == null) return null;
    return value as int;
  }

  Future<double?> getAsDouble(String key) async {
    final value = await get(key);
    if (value == null) return null;
    return value as double;
  }

  Future<bool?> getAsBool(String key) async {
    final value = await get(key);
    if (value == null) return null;
    return value as bool;
  }

  Future<Map<String, dynamic>?> getAsJson(String key) async {
    final value = await get(key);
    if (value == null) return null;
    return value as Map<String, dynamic>;
  }

  Future<dynamic> put(String key, dynamic value) async {
    if (!(value is String ||
        value is int ||
        value is bool ||
        value is double ||
        value is Map<String, dynamic>))
      throw UnsupportedError(
          'Supported types for put operations are only String, int, double, bool and json object.');
    l.info('Put setting with key "$key" and value "$value"');
    final storedValue = await _store.record(key).put(_db, value);
    l.info('Put for key "$key" successful');
    return storedValue;
  }

  Future purge({String? key}) async {
    if (key != null) return await _store.record(key).delete(_db);
    return await _store.delete(_db);
  }
}
