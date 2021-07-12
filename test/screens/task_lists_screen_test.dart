import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/models/task_list.dart';
import 'package:p2p_task/screens/task_list_screen.dart';
import 'package:p2p_task/screens/task_lists_screen.dart';
import 'package:p2p_task/screens/task_list_form_screen.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:provider/provider.dart';
import 'package:sembast/sembast.dart' hide Finder;
import 'package:sembast/sembast_memory.dart';

import '../utils.dart';

void main() {
  late Database database;
  late TaskListService taskListService;
  late TaskList taskList;
  late Widget app;

  setUpAll(() async {
    database = await databaseFactoryMemory.openDatabase('');
    taskListService = await initTaskListService(database);
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

  tearDownAll(() async {
    await database.close();
  });

  group('TaskListsScreen without lists', () {
    testWidgets('asks user to add a list', (WidgetTester tester) async {
      await pumpAppAndSettle(tester, app);

      final callToActionFinder =
          find.text('Click the plus button below to add a list.');
      expect(callToActionFinder, findsOneWidget);
    });

    testWidgets(
      'shows plus button to add a new list',
      (WidgetTester tester) async {
        await pumpAppAndSettle(tester, app);

        final addButtonFinder = find.byKey(Key('addTaskListButton'));
        expect(addButtonFinder, findsOneWidget);
      },
    );
  });

  group('TaskListsScreen tiles', () {
    setUp(() async {
      await taskListService.upsertTaskList(taskList);
    });

    tearDown(() async {
      await taskListService.removeTaskList(taskList.id!);
    });

    testWidgets(
      'should have a visible list on screen when one added',
      (WidgetTester tester) async {
        await pumpAppAndSettle(tester, app);

        var listTileFinder = find.byType(ListTile);
        var listTitleFinder = find.descendant(
          of: listTileFinder,
          matching: find.text('Test List'),
        );

        listTileFinder = find.byType(ListTile);
        expect(listTileFinder, findsOneWidget);
        listTitleFinder = find.descendant(
          of: listTileFinder,
          matching: find.text('Test List'),
        );
        expect(listTitleFinder, findsOneWidget);
      },
    );

    testWidgets(
      'should have a list edit option behind slider',
      (WidgetTester tester) async {
        await pumpAppAndSettle(tester, app);

        final slidableTaskListTile = find.byType(Slidable);
        expect(slidableTaskListTile, findsOneWidget);
        await slideWidgetOpen(tester, slidableTaskListTile);
        expect(find.byIcon(Icons.edit), findsOneWidget);
      },
    );

    testWidgets(
      'should have a list deletion option behind slider',
      (WidgetTester tester) async {
        await pumpAppAndSettle(tester, app);

        final slidableTaskListTile = find.byType(Slidable);
        expect(slidableTaskListTile, findsOneWidget);
        await slideWidgetOpen(tester, slidableTaskListTile);
        expect(find.byIcon(Icons.delete), findsOneWidget);
      },
    );

    testWidgets('should allow list deletion', (WidgetTester tester) async {
      await pumpAppAndSettle(tester, app);

      final slidableTaskListTile = find.byType(Slidable);
      await slideWidgetOpen(tester, slidableTaskListTile);
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final lists = await taskListService.taskLists;
        expect(lists, isEmpty);
      });
    });
  });

  group('TaskListScreen transitions to', () {
    setUpAll(() async {
      await taskListService.upsertTaskList(taskList);
    });

    tearDownAll(() async {
      await taskListService.removeTaskList(taskList.id!);
    });

    testWidgets(
      'TaskListFormScreen when clicking the add-button',
      (WidgetTester tester) async {
        await pumpAppAndSettle(tester, app);

        final addButtonFinder = find.byKey(Key('addTaskListButton'));
        await tester.tap(addButtonFinder);
        await tester.pumpAndSettle();
        expect(find.byType(TaskListFormScreen), findsOneWidget);
      },
    );

    testWidgets(
      'TaskListFormScreen when clicking the edit-button',
      (WidgetTester tester) async {
        await pumpAppAndSettle(tester, app);
        final slidableTaskListTile = find.byType(Slidable);
        await slideWidgetOpen(tester, slidableTaskListTile);
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();
        expect(find.byType(TaskListFormScreen), findsOneWidget);
      },
    );

    testWidgets(
      'TasksListScreen when clicking the TaskListTile',
      (WidgetTester tester) async {
        await pumpAppAndSettle(tester, app);
        await tester.tap(find.byType(ListTile));
        await tester.pumpAndSettle();
        expect(find.byType(TaskListScreen), findsOneWidget);
      },
    );
  });
}
