import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';

class DeviceTaskList {
  final Database database;
  final KeyValueRepository keyValueRepository;
  final IdentityService identityService;
  final SyncService syncService;
  final TaskListService taskListService;

  DeviceTaskList(
    this.database,
    this.keyValueRepository,
    this.identityService,
    this.syncService,
    this.taskListService,
  );

  static Future<DeviceTaskList> create({
    DatabaseFactory? databaseFactory,
    String? databasePath,
    String? name,
  }) async {
    final database = await (databaseFactory ?? newDatabaseFactoryMemory())
        .openDatabase(databasePath ?? sembastInMemoryDatabasePath);
    final keyValueRepository = KeyValueRepository(database);
    final identityService = IdentityService(keyValueRepository);
    if (name != null) await identityService.setName(name);
    final syncService = SyncService(keyValueRepository);
    final taskListService =
        TaskListService(keyValueRepository, identityService, syncService);

    return DeviceTaskList(
      database,
      keyValueRepository,
      identityService,
      syncService,
      taskListService,
    );
  }

  Future<void> close() {
    return database.close();
  }
}
