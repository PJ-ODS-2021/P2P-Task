import 'package:p2p_task/config/migrations.dart';
import 'package:p2p_task/utils/platform_database_factory.dart';
import 'package:sembast/sembast.dart';

class DatabaseService {
  final _databaseFactory;
  final String databaseName;
  final int currentVersion;
  final VersionedMigrationFunctionDispenser? _migrationFunctionDispenser;
  Database? _database;
  String? _dbPath;

  Database? get database => _database;

  DatabaseService(
    PlatformDatabaseFactory databaseFactory, {
    int? version,
    String? databaseName,
    bool? inMemory,
    VersionedMigrationFunctionDispenser? migrationDispenser,
  })  : _databaseFactory = databaseFactory
          ..inMemory = inMemory ?? false
          ..databaseName = databaseName ?? 'P2P Task',
        currentVersion = version ?? 1,
        databaseName = databaseName ?? 'P2P Task',
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
