import 'package:sembast/sembast.dart';

typedef MigrationFunction = Future<void> Function(Database);

class VersionedMigrationFunctionDispenser {
  final Map<int, MigrationFunction> migrations = {
    1: (db) async => null,
  };

  MigrationFunction? get(int version) => migrations[version];
}
