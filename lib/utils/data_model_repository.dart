import 'package:p2p_task/utils/data_model.dart';
import 'package:p2p_task/utils/log_mixin.dart';
import 'package:sembast/sembast.dart';
import 'package:uuid/uuid.dart';

typedef Converter<T> = T Function(Map<String, dynamic> json);

class DataModelRepository<T extends DataModel> with LogMixin {
  final Database _db;
  final Converter<T> _converter;
  final StoreRef<String, Map<String, dynamic>> _store;

  DataModelRepository(
    Database database,
    Converter<T> converter,
    String typeName,
  )   : _db = database,
        _converter = converter,
        _store = StoreRef(typeName);

  Future<T?> get(String id, {DatabaseClient? txn}) async {
    logger.info('Get entry with type "${_store.name}" and id "$id"');
    final entry = await _store.record(id).get(txn ?? _db);
    if (entry == null) return null;
    logger.info(entry);

    return _converter(entry);
  }

  Future<List<T>> find({Finder? finder, DatabaseClient? txn}) async {
    logger.info('Get entries with type "${_store.name}"');
    final entries =
        (await _store.find(txn ?? _db, finder: finder)).map((e) => e.value);
    logger.info(entries);

    return entries.map((e) => _converter(e)).toList();
  }

  Future<T> upsert(T object, {DatabaseClient? txn}) async {
    logger.info('Upsert entry with type "${_store.name}"');
    final db = txn ?? _db;
    var id = object.id;
    final hasId = id != null;
    if (!hasId) object.id = Uuid().v4();
    final record = _store.record(object.id!);
    final existsInDatabase = hasId ? await record.exists(txn ?? _db) : false;
    if (existsInDatabase) {
      await record.update(db, object.toJson());
    } else {
      id = await record.add(db, object.toJson());
    }
    logger.info(object.toJson());

    return _converter((await _store.record(id!).get(db))!);
  }

  Future<void> remove(String id, {DatabaseClient? txn}) async {
    logger.info('Remove entry with type "${_store.name}" and id "$id"');
    final db = txn ?? _db;
    if (await _store.record(id).exists(db)) {
      await _store.record(id).delete(db);
    }
    logger.info('Removed entry with type "${_store.name}" and id "$id"');
  }

  Future<int> count({Filter? filter, DatabaseClient? txn}) async {
    return await _store.count(txn ?? _db, filter: filter);
  }

  Future runTransaction(Function(DatabaseClient txn) func) async {
    await _db.transaction((txn) async {
      try {
        await func(txn);
      } catch (error, stackTrace) {
        logger.severe(
          'Error occurred while running a transaction.',
          error,
          stackTrace,
        );
      }
    });
  }
}
