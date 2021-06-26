import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/models/task_list.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:uuid/uuid.dart';

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

  test('create task list', () async {
    final id = Uuid().v4();
    await taskListService.upsertTaskList(TaskList(id: id, title: 'list1'));
    final taskListRecordMap = await taskListService.taskListRecordMap;
    expect(taskListRecordMap.keys.toSet(), {id});
    expect(taskListRecordMap[id]?.value?.title, 'list1');
  });

  test('should store and retrieve tasks after first task is deleted', () async {
    const taskTitle1 = 'Catch a cat falling from the sky';
    const taskTitle2 = 'Drink a cold cat';

    await taskListService.upsertTaskList(TaskList(id: 'id1', title: 'list1'));
    await taskListService.upsertTask('id1', Task(title: taskTitle1));
    var tasks = (await taskListService.allTasks).toList();
    expect(tasks.length, 1);
    expect(tasks.first.title, taskTitle1);
    final taskId = tasks.first.id!;
    expect(taskId, isNot(null));

    await taskListService.removeTask('id1', taskId);
    tasks = (await taskListService.allTasks).toList();
    expect(tasks.isEmpty, true);

    await taskListService.upsertTask('id1', Task(title: taskTitle2));
    tasks = (await taskListService.allTasks).toList();

    expect(tasks.length, 1);
    expect(tasks.first.title, taskTitle2);
  });

  tearDown(() async {
    await database.close();
  });
}
