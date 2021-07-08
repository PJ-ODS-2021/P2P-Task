import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:p2p_task/models/task_list.dart';
import 'package:p2p_task/screens/task_form_screen.dart';
import 'package:p2p_task/screens/task_list_screen.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:provider/provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  late Database db;
  late KeyValueRepository keyValueRepository;
  late IdentityService identityService;
  late TaskListService taskListService;
  late SyncService syncService;
  late TaskList taskList;

  setUp(() async {
    db = await databaseFactoryMemory.openDatabase('');
    keyValueRepository = KeyValueRepository(db, StoreRef(''));
    identityService = IdentityService(keyValueRepository);
    syncService = SyncService(keyValueRepository);
    await syncService.setInterval(0);
    taskListService =
        TaskListService(keyValueRepository, identityService, syncService);
    taskList = TaskList(
      title: 'Add-Task Button opens Task Creation Form',
    );
  });
  testWidgets('Add new task', (WidgetTester tester) async {
    final mockObserver = MockNavigatorObserver();
    await tester.pumpWidget(Provider<ChangeCallbackNotifier<TaskListService>>(
      create: (c) {
        return ChangeCallbackNotifier<TaskListService>(taskListService);
      },
      child: TaskListScreen(taskList),
    ));
    expect(find.byIcon(Icons.add), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    verify(mockObserver.didPush(
        MaterialPageRoute(builder: (_) => TaskFormScreen(taskListID: '1')),
        any));
    expect(find.byType(TaskFormScreen), findsOneWidget);
  });

  testWidgets('Tap on task sets uncompleted task as completed',
      (WidgetTester tester) async {
    await tester.pumpWidget(Provider<ChangeCallbackNotifier<TaskListService>>(
      create: (c) {
        return ChangeCallbackNotifier<TaskListService>(taskListService);
      },
      child: TaskListScreen(taskList),
    ));
    expect(find.byType(ListTile), findsOneWidget);
    await tester.tap(find.byType(ListTile));
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('Can create a task with a title and a description',
      (WidgetTester tester) async {
    final mockObserver = MockNavigatorObserver();
    await tester.pumpWidget(MaterialApp(
      home: TaskFormScreen(taskListID: '1'),
      navigatorObservers: [mockObserver],
    ));
    await tester.enterText(find.byKey(Key('title')), 'Title');
    await tester.enterText(find.byKey(Key('description')), 'Description');
    expect(find.byType(ElevatedButton), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(Duration(seconds: 1));
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    verify(mockObserver.didPop(
        MaterialPageRoute(builder: (_) => TaskListScreen(taskList)), any));
  });

  tearDown(() async {
    await db.close();
  });
}
