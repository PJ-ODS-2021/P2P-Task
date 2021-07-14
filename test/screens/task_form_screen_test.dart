import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/models/task_list.dart';
import 'package:p2p_task/screens/task_form_screen.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:provider/provider.dart';
import 'package:sembast/sembast.dart';

import '../utils/device_task_list.dart';
import '../utils/widgets.dart';

void main() {
  late Database database;
  late TaskListService taskListService;
  late TaskList taskList;
  late Widget app;

  setUp(() async {
    final deviceTaskList = await DeviceTaskList.create(name: 'Test Device');
    database = deviceTaskList.database;
    taskListService = deviceTaskList.taskListService;
    taskList = TaskList(
      title: 'Important Test Tasks ✨',
    );
    await taskListService.upsertTaskList(taskList);

    final providers = [
      ChangeNotifierProvider(
        create: (_) => ChangeCallbackNotifier<TaskListService>(taskListService),
      ),
    ];
    app = buildAppWithScreen(
      TaskFormScreen(taskListID: taskList.id!),
      providers,
    );
  });

  testWidgets(
    'TaskForm can create a task with title and description',
    (WidgetTester tester) async {
      await pumpAppAndSettle(tester, app);
      final title = 'Do something important';
      final description = 'Like writing tests';
      await tester.enterText(find.byKey(Key('taskTitle')), title);
      await tester.enterText(find.byKey(Key('taskDescription')), description);
      expect(find.byType(ElevatedButton), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final tasks = await taskListService.getTasksFromList(taskList.id!);
        expect(tasks.length, 1);
        final createdTask = tasks.first;
        expect(createdTask.title, title);
        expect(createdTask.description, description);
        expect(createdTask.completed, false);
      });
    },
  );

  testWidgets(
    'TaskForm expects the title to be given',
    (WidgetTester tester) async {
      await pumpAppAndSettle(tester, app);
      final description = 'Like writing tests';
      await tester.enterText(find.byKey(Key('taskDescription')), description);
      expect(find.byType(ElevatedButton), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      final titleMissingWarning =
          find.widgetWithText(TextFormField, 'Give your task a title.');
      expect(titleMissingWarning, findsOneWidget);
    },
  );

  tearDown(() async {
    await taskListService.removeTaskList(taskList.id!);
    await database.close();
  });
}
