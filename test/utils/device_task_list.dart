import 'package:p2p_task/security/key_helper.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
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
    await _createKeys(identityService);
    final taskListService =
        TaskListService(keyValueRepository, identityService, null);

    return DeviceTaskList(
      database,
      keyValueRepository,
      identityService,
      taskListService,
    );
  }

  static Future<void> _createKeys(IdentityService identityService) async {
    final keyHelper = KeyHelper();
    final keys = keyHelper.generateRSAKeyPair();
    final privateKey = keyHelper.encodePrivateKeyToPem(keys.privateKey);
    final publicKey = keyHelper.encodePublicKeyToPem(keys.publicKey);
    await identityService.setPrivateKeyPem(privateKey);
    await identityService.setPublicKeyPem(publicKey);
  }

  Future<void> close() {
    return database.close();
  }
}
