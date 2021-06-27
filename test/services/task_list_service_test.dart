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
    final taskListRecordMap = await taskListService.taskLists;
    expect(taskListRecordMap.map((e) => e.id!), [id]);
    expect(taskListRecordMap.first.title, 'list1');
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

  test('should retrieve tasks with allTaskRecords', () async {
    final task1 = Task(title: 'Catch a cat falling from the sky');
    final task2 = Task(title: 'Drink a cold cat');
    await taskListService.upsertTaskList(TaskList(id: 'id1', title: 'list1'));
    await taskListService.upsertTask('id1', task1);
    await taskListService.upsertTask('id1', task2);

    final allTaskRecords = (await taskListService.allTaskRecords).toList();
    expect(allTaskRecords.length, 2);
    expect(allTaskRecords.map((v) => v.task).toSet(), {task1, task2});
    expect(allTaskRecords.map((v) => v.taskListId).toList(), ['id1', 'id1']);
  });

  test('should retrieve deleted task record with allTaskRecords', () async {
    final task1 = Task(title: 'Catch a cat falling from the sky');
    await taskListService.upsertTaskList(TaskList(id: 'id1', title: 'list1'));
    await taskListService.upsertTask('id1', task1);
    await taskListService.removeTask('id1', task1.id!);

    final allTaskRecords = (await taskListService.allTaskRecords).toList();
    expect(allTaskRecords.length, 1);
    expect(allTaskRecords.first.task, null);
  });

  tearDown(() async {
    await database.close();
  });
}
