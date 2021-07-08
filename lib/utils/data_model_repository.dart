import 'package:p2p_task/utils/data_model.dart';
import 'package:p2p_task/utils/log_mixin.dart';
import 'package:sembast/sembast.dart';
import 'package:uuid/uuid.dart';

typedef Converter<T> = T Function(Map<String, dynamic> json);

class DataModelRepository<T extends DataModel> with LogMixin {
  Transaction? _transaction;
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

  Future<T?> get(String id) async {
    l.info('Get entry with type "${_store.name}" and id "$id"');
    final entry = await _store.record(id).get(_dbClient);
    if (entry == null) return null;
    l.info(entry);

    return _converter(entry);
  }

  Future<List<T>> find({Finder? finder}) async {
    l.info('Get entries with type "${_store.name}"');
    final entries =
        (await _store.find(_dbClient, finder: finder)).map((e) => e.value);
    l.info(entries);

    return entries.map((e) => _converter(e)).toList();
  }

  Future<T> upsert(T object) async {
    l.info('Upsert entry with type "${_store.name}"');
    var id = object.id;
    final hasId = id != null;
    if (!hasId) object.id = Uuid().v4();
    final record = _store.record(object.id!);
    final existsInDatabase = hasId ? await record.exists(_dbClient) : false;
    if (existsInDatabase) {
      await record.update(_dbClient, object.toJson());
    } else {
      id = await record.add(_db, object.toJson());
    }
    l.info(object.toJson());

    return _converter((await _store.record(id!).get(_dbClient))!);
  }

  Future<void> remove(String id) async {
    l.info('Remove entry with type "${_store.name}" and id "$id"');
    if (await _store.record(id).exists(_dbClient)) {
      await _store.record(id).delete(_dbClient);
    }
    l.info('Removed entry with type "${_store.name}" and id "$id"');
  }

  Future<int> count({Filter? filter}) async {
    return await _store.count(_dbClient, filter: filter);
  }

  Future runTxn(Function() func) async {
    await _db.transaction((transaction) {
      _transaction = transaction;
      try {
        func();
      } catch (error, stackTrace) {
        _transaction = null;
        l.severe(
          'Error occurred while running a transaction.',
          error,
          stackTrace,
        );
      }
      _transaction = null;
    });
  }

  DatabaseClient get _dbClient => _transaction ?? _db;
}
