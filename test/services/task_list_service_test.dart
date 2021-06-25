import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  late Database database;
  late KeyValueRepository keyValueRepository;
  late IdentityService identityService;
  late SyncService syncService;
  late TaskListService taskListService;

  setUp(() async {
    database = await databaseFactoryMemory.openDatabase('');
    keyValueRepository = KeyValueRepository(database);
    identityService = IdentityService(keyValueRepository);
    syncService = SyncService(keyValueRepository);
    taskListService =
        TaskListService(keyValueRepository, identityService, syncService);
  });

  test('should store and retrieve tasks after first task is deleted', () async {
    final taskTitle = 'Drink a cold cat';

    await taskListService.upsert(
        Task(title: 'Catch a cat falling from the sky', taskListID: '1'));
    final task = (await taskListService.tasks).first;
    await taskListService.remove(task);
    await taskListService.upsert(Task(title: taskTitle, taskListID: '1'));
    final tasks = await taskListService.tasks;

    expect(tasks.length, equals(1));
    expect(tasks.first.title, equals(taskTitle));
  });

  tearDown(() async {
    await database.close();
  });
}
