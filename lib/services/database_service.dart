import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:p2p_task/config/migrations.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:sembast_web/sembast_web.dart';

class DatabaseService {
  final String databaseName;
  final int currentVersion;
  final bool _inMemory;
  final Map<int, MigrationFunction> _migrations;
  Database? _database;

  Database? get database => _database;

  DatabaseService(
    int version,
    String databaseName,
    bool inMemory,
    Map<int, MigrationFunction> migrations,
  )   : currentVersion = version,
        databaseName = databaseName,
        _inMemory = inMemory,
        _migrations = migrations;

  Future<void> create({String? dbPath}) async {
    if (_inMemory) {
      _database = await databaseFactoryMemory.openDatabase(
        databaseName,
        version: currentVersion,
        onVersionChanged: _handleVersionChanged,
      );

      return;
    }

    if (kIsWeb) {
      _database = await databaseFactoryWeb.openDatabase(
        databaseName,
        version: currentVersion,
        onVersionChanged: _handleVersionChanged,
      );

      return;
    }

    var finalPath = '';
    if (dbPath == null || dbPath.isEmpty) {
      // no need to request Permission.storage
      final dir = await getApplicationDocumentsDirectory();
      final appDir = Directory(path.join(dir.path, databaseName));
      await appDir.create(recursive: true);
      finalPath = path.join(appDir.path, '$databaseName.db');
    } else {
      finalPath = path.join(dbPath, '$databaseName.db');
    }

    _database = await databaseFactoryIo.openDatabase(
      finalPath,
      version: currentVersion,
      onVersionChanged: _handleVersionChanged,
    );
  }

  Future<void> move(String path) async {
    if (_database == null || _inMemory || kIsWeb) {
      return;
    }
    // TODO: Implement
    await databaseFactoryIo.deleteDatabase(_database!.path);
    await create(dbPath: path);
  }

  Future<void> clear() async {
    await delete();
    await create();
  }

  Future<void> delete() async {
    if (_database == null) {
      return;
    }
    if (_inMemory) {
      await databaseFactoryMemory.deleteDatabase(databaseName);
    } else if (kIsWeb) {
      await databaseFactoryWeb.deleteDatabase(databaseName);
    } else {
      await databaseFactoryIo.deleteDatabase(_database!.path);
    }
  }

  Future<void> _handleVersionChanged(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    final relevantMigrations = [];
    for (final migrationEntry in _migrations.entries) {
      if (migrationEntry.key > oldVersion) {
        relevantMigrations.add(migrationEntry);
      }
    }
    relevantMigrations.sort((a, b) => a.key - b.key);

    for (final migration in relevantMigrations) {
      await migration.value(database);
    }
  }

  Future<void> deleteStore(String name) async {
    if (_database != null) await StoreRef(name).delete(_database!);
  }
}
