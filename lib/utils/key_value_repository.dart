import 'dart:async';

import 'package:p2p_task/utils/log_mixin.dart';
import 'package:sembast/sembast.dart';

class KeyValueRepository with LogMixin {
  final Database _db;
  final StoreRef<String, dynamic> _store;

  KeyValueRepository(Database database, StoreRef<String, dynamic> store)
      : _db = database,
        _store = store;

  /// [T] must be supported by sembast
  Future<T?> get<T>(String key) async {
    return (await _store.record(key).get(_db)) as T?;
  }

  /// [value] must have a type that is supported by sembast
  Future<dynamic> put(String key, dynamic value) async {
    if (key == 'privateKeyKey') {
      logger.info('Put setting with key "$key"');
    } else {
      logger.info('Put setting with key "$key" and value "$value"');
    }

    return await _store.record(key).put(_db, value);
  }

  Future purge({String? key}) async {
    if (key != null) return await _store.record(key).delete(_db);

    return await _store.delete(_db);
  }
}
