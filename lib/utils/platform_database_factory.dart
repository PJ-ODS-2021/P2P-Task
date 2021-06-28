import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:sembast_web/sembast_web.dart';

class PlatformDatabaseFactory extends DatabaseFactory {
  String _databaseName = '';
  bool _inMemory = false;

  set databaseName(String databaseName) => _databaseName = databaseName;

  set inMemory(bool inMemory) => _inMemory = inMemory;

  @override
  Future<void> deleteDatabase(String path) async {
    if (_inMemory) return databaseFactoryMemory.deleteDatabase(_databaseName);
    if (kIsWeb) return databaseFactoryWeb.deleteDatabase(_databaseName);
    await databaseFactoryIo.deleteDatabase(path);
  }

  @override
  bool get hasStorage => !_inMemory;

  @override
  Future<Database> openDatabase(
    String path, {
    int? version,
    OnVersionChangedFunction? onVersionChanged,
    DatabaseMode? mode,
    SembastCodec? codec,
  }) async {
    if (_inMemory) {
      return databaseFactoryMemory.openDatabase(
        _databaseName,
        version: version,
        onVersionChanged: onVersionChanged,
        mode: mode,
        codec: codec,
      );
    }
    if (kIsWeb) {
      return databaseFactoryWeb.openDatabase(
        _databaseName,
        version: version,
        onVersionChanged: onVersionChanged,
        mode: mode,
        codec: codec,
      );
    }

    return databaseFactoryIo.openDatabase(
      await _finalPath(path),
      version: version,
      onVersionChanged: onVersionChanged,
      mode: mode,
      codec: codec,
    );
  }

  Future<String> _finalPath(String dbPath) async {
    var finalPath = '';
    if (dbPath.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      final appDir = Directory(path.join(dir.path, _databaseName));
      await appDir.create(recursive: true);
      finalPath = path.join(appDir.path, '$_databaseName.json');
    } else {
      finalPath = path.join(dbPath, '$_databaseName.json');
    }

    return finalPath;
  }
}
