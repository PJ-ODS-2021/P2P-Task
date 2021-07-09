import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/task_list/task_list_service.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';

class DeviceTaskList {
  final Database database;
  final KeyValueRepository keyValueRepository;
  final IdentityService identityService;
  final TaskListService taskListService;

  DeviceTaskList(
    this.database,
    this.keyValueRepository,
    this.identityService,
    this.taskListService,
  );

  static Future<DeviceTaskList> create({
    DatabaseFactory? databaseFactory,
    String? databasePath,
    String? name,
  }) async {
    final database = await (databaseFactory ?? newDatabaseFactoryMemory())
        .openDatabase(databasePath ?? sembastInMemoryDatabasePath);
    final keyValueRepository = KeyValueRepository(database, StoreRef(''));
    final identityService = IdentityService(keyValueRepository);
    if (name != null) await identityService.setName(name);
    final taskListService =
        TaskListService(keyValueRepository, identityService, null);

    return DeviceTaskList(
      database,
      keyValueRepository,
      identityService,
      taskListService,
    );
  }

  Future<void> close() {
    return database.close();
  }
}
