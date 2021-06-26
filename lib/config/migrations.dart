import 'package:sembast/sembast.dart';

typedef MigrationFunction = Future<void> Function(Database);

final Map<int, MigrationFunction> migrations = {
  1: (db) async => null,
};
