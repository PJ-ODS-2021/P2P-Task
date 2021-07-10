import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:p2p_task/models/task_list.dart';
import 'package:p2p_task/screens/task_lists_screen.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:provider/provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';

class MRockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  late Database database;
  late KeyValueRepository keyValueRepository;
  late IdentityService identityService;
  late TaskListService taskListService;
  late SyncService syncService;
  late TaskList taskList;
  late Widget app;

  setUp(() async {
    database = await databaseFactoryMemory.openDatabase('');
    keyValueRepository = KeyValueRepository(database, StoreRef(''));
    identityService = IdentityService(keyValueRepository);
    syncService = SyncService(keyValueRepository);
    await syncService.setInterval(0);
    taskListService = TaskListService(
      keyValueRepository,
      identityService,
      syncService,
    );
    taskList = TaskList(title: 'Test List');
    app = MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              ChangeCallbackNotifier<TaskListService>(taskListService),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: TaskListsScreen(),
        ),
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('TaskListsScreen without lists', () {
    testWidgets('asks user to add a list', (WidgetTester tester) async {
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      final callToActionFinder =
      find.text('Click the plus button below to add a list.');
      expect(callToActionFinder, findsOneWidget);
    });
  });

  group('TaskListsScreen with lists', () {
    testWidgets('should have a visible list on screen when one added', (WidgetTester tester) async {
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      var listTileFinder = find.byType(ListTile);
      expect(listTileFinder, findsNothing);
      var listTitleFinder = find.descendant(
        of: listTileFinder, matching: find.text('Test List'),);
      expect(listTitleFinder, findsNothing);

      await tester.runAsync(() async {
        final lists = await taskListService.taskLists;
        expect(lists, isEmpty);
        await taskListService.upsertTaskList(taskList);
      });

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      listTileFinder = find.byType(ListTile);
      expect(listTileFinder, findsOneWidget);
      listTitleFinder = find.descendant(
        of: listTileFinder, matching: find.text('Test List'),);
      expect(listTitleFinder, findsOneWidget);
    });
  });
}
