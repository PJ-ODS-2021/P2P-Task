import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';

class DatabaseCreator {
  static Database? _db;

  static Future<Database> create() async {
    if (_db != null) return _db!;
    if (kIsWeb) return await databaseFactoryWeb.openDatabase('p2p_task');

    // no need to request Permission.storage
    final dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    var dbPath = join(dir.path, 'p2p_task.db');
    return _db = await databaseFactoryIo.openDatabase(dbPath);
  }
}
