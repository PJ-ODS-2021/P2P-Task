import 'package:p2p_task/config/migrations.dart';
import 'package:sembast/sembast.dart';

class DatabaseService {
  static const databaseNameDefault = 'p2p_task';
  static const inMemoryDefault = false;
  static const versionDefault = 1;
  final _databaseFactory;
  final int currentVersion;
  final VersionedMigrationFunctionDispenser? _migrationFunctionDispenser;
  Database? _database;
  String? _dbPath;

  Database? get database => _database;

  DatabaseService(
    DatabaseFactory Function(String, bool) factoryProvider, {
    int? version,
    String? databaseName,
    bool? inMemory,
    VersionedMigrationFunctionDispenser? migrationDispenser,
  })  : assert(databaseName != null ? databaseName.isNotEmpty : false),
        _databaseFactory = factoryProvider(
          databaseName ?? databaseNameDefault,
          inMemory ?? inMemoryDefault,
        ),
        currentVersion = version ?? versionDefault,
        _migrationFunctionDispenser = migrationDispenser;

  Future<void> create({String? dbPath}) async {
    _dbPath = dbPath;
    _database = await _databaseFactory.openDatabase(
      dbPath ?? '',
      version: currentVersion,
      onVersionChanged: _handleVersionChanged,
    );
  }

  Future<void> clear() async {
    await delete();
    await create(dbPath: _dbPath);
  }

  Future<void> delete() async {
    if (_database == null) {
      return;
    }
    await _database!.close();
    await _databaseFactory.deleteDatabase(_database!.path);
  }

  Future<void> _handleVersionChanged(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    for (var i = oldVersion + 1; i <= newVersion; i++) {
      final migrationFunction = _migrationFunctionDispenser?.get(i);
      if (migrationFunction != null) await migrationFunction(database);
    }
  }

  Future<void> deleteStore(String name) async {
    if (_database != null) await StoreRef(name).delete(_database!);
  }

  Future<void> close() async {
    await _database?.close();
  }
}
