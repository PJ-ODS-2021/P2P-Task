import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';

class DatabaseCreator {
  static Database? _db;

  static Future<Database> create() async {
    if (_db != null) return _db!;
    if (kIsWeb) {
      _db = await databaseFactoryWeb.openDatabase('p2p_task');
    } else {
      // Need to check for Android or iOS permissions
      if (Platform.isAndroid || Platform.isIOS) {
        final status = await perm.Permission.storage.request();
        if (!status.isGranted) exit(-1);
      }
      final dir = await getApplicationDocumentsDirectory();
      await dir.create(recursive: true);
      var dbPath = join(dir.path, 'p2p_task.db');
      _db = await databaseFactoryIo.openDatabase(dbPath);
    }
    return _db!;
  }
}
