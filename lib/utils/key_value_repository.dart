import 'package:p2p_task/utils/log_mixin.dart';
import 'package:sembast/sembast.dart';

class KeyValueRepository with LogMixin {
  final Database? _db;
  final StoreRef<String, dynamic> _store;

  KeyValueRepository(this._db) : this._store = StoreRef('Settings');

  /// [T] must be supported by sembast
  Future<T?> get<T>(String key) async {
    if (_db == null) {
      l.warning(
          'Trying to get a value from a repository without database. The value will always be null.');
      return null;
    }
    return (await _store.record(key).get(_db!)) as T?;
  }

  /// [value] must have a type that is supported by sembast
  Future<dynamic> put(String key, dynamic value) async {
    if (_db == null) {
      l.warning(
          'Trying to put a value into a repository without database. The value will not be stored.');
      return null;
    }
    l.info('Put setting with key "$key" and value "$value"');
    return await _store.record(key).put(_db!, value);
  }

  Future purge({String? key}) async {
    if (_db == null) return;
    if (key != null) return await _store.record(key).delete(_db!);
    return await _store.delete(_db!);
  }

  bool get hasDatabase => _db != null;
}
