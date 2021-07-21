import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/models/task_list.dart';
import 'package:p2p_task/screens/task_form_screen.dart';
import 'package:p2p_task/screens/task_list_screen.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/task_list/task_list_service.dart';
import 'package:provider/provider.dart';

import '../utils/device_task_list.dart';
import '../utils/widgets.dart';

void main() {
  late DeviceTaskList deviceTaskList;
  late TaskListService taskListService;
  late TaskList taskList;
  late Task task;
  late Widget app;

  setUpAll(() async {
    deviceTaskList = await DeviceTaskList.create(name: 'Test Device');
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
    app = buildAppWithScreen(TaskListScreen(taskList), providers);
  });

  tearDownAll(() async {
    await deviceTaskList.close();
  });

  group(
    'TaskListScreen transitions to',
    () {
      setUpAll(() async {
        task = Task(
          title: 'Test ALL the things!',
          description: 'This is a ToDo created for testing purposes.',
        );
        await taskListService.upsertTask(taskList.id!, task);
      });

      tearDownAll(() async {
        await taskListService.removeTask(taskList.id!, task.id!);
      });

      testWidgets(
        'TaskFormScreen when clicking the add-button',
        (WidgetTester tester) async {
          await pumpAppAndSettle(tester, app);

          final addButtonFinder = find.byKey(Key('addTaskButton'));
          await tester.tap(addButtonFinder);
          await tester.pumpAndSettle();
          expect(find.byType(TaskFormScreen), findsOneWidget);
        },
      );

      testWidgets(
        'TaskFormScreen when clicking the edit-button',
        (WidgetTester tester) async {
          await pumpAppAndSettle(tester, app);

          await findAndSlideWidgetOpen(tester);
          await tester.tap(find.byIcon(Icons.edit));
          await tester.pumpAndSettle();
          expect(find.byType(TaskFormScreen), findsOneWidget);
        },
      );
    },
  );

  group(
    'TaskListScreen without tasks',
    () {
      testWidgets(
        'asks user to add a task',
        (WidgetTester tester) async {
          await pumpAppAndSettle(tester, app);

          final callToActionFinder =
              find.text('Click the plus button below to add a ToDo.');
          expect(callToActionFinder, findsOneWidget);
        },
      );

      testWidgets(
        'shows plus button to add a new task',
        (WidgetTester tester) async {
          await pumpAppAndSettle(tester, app);

          final addButtonFinder = find.byKey(Key('addTaskButton'));
          expect(addButtonFinder, findsOneWidget);
        },
      );
    },
  );

  group(
    'Task tiles',
    () {
      setUp(() async {
        task = Task(
          title: 'Test ALL the things!',
          description: 'This is a ToDo created for testing purposes.',
        );
        await taskListService.upsertTask(taskList.id!, task);
      });

      tearDown(() async {
        await taskListService.removeTask(taskList.id!, task.id!);
      });

      testWidgets(
        "should show a task's title",
        (WidgetTester tester) async {
          await pumpAppAndSettle(tester, app);

          final taskTileFinder = find.widgetWithText(ListTile, task.title);
          expect(taskTileFinder, findsOneWidget);
        },
      );

      testWidgets(
        "should show a task's description",
        (WidgetTester tester) async {
          await pumpAppAndSettle(tester, app);

          final taskTileFinder =
              find.widgetWithText(ListTile, task.description!);
          expect(taskTileFinder, findsOneWidget);
        },
      );

      testWidgets(
        'should have an edit option behind slider',
        (WidgetTester tester) async {
          await pumpAppAndSettle(tester, app);

          await findAndSlideWidgetOpen(tester);
          expectSlideActionWith(Icons.edit, 'Edit');
        },
      );

      testWidgets(
        'should have a flag option behind slider',
        (WidgetTester tester) async {
          await pumpAppAndSettle(tester, app);

          await findAndSlideWidgetOpen(tester);
          expectSlideActionWith(Icons.flag, 'Flag');
        },
      );

      testWidgets(
        'should have a delete option behind slider',
        (WidgetTester tester) async {
          await pumpAppAndSettle(tester, app);

          await findAndSlideWidgetOpen(tester);
          expectSlideActionWith(Icons.delete, 'Delete');
        },
      );

      testWidgets(
        'should allow flagging a task',
        (WidgetTester tester) async {
          await pumpAppAndSettle(tester, app);

          await findAndSlideWidgetOpen(tester);
          await tester.tap(find.widgetWithText(IconSlideAction, 'Flag'));
          await tester.pumpAndSettle();

          await tester.runAsync(() async {
            final taskRecords =
                (await taskListService.getTaskListById(taskList.id!))?.elements;
            expect(taskRecords, isNot(null));
            expect(taskRecords!.length, 1);
            final task = taskRecords.first;
            expect(task.isFlagged, true);
          });
        },
      );

      testWidgets(
        'show Red Flag for flagged task',
        (WidgetTester tester) async {
          await tester.runAsync(() async {
            await taskListService.upsertTask(
              taskList.id!,
              task..isFlagged = true,
            );
          });
          await pumpAppAndSettle(tester, app);
          final flaggedTaskIcon =
              (tester.firstWidget(find.byIcon(Icons.flag)) as Icon);

          expect(flaggedTaskIcon.color, Colors.red);
          expect(flaggedTaskIcon.semanticLabel, 'High Priority');
        },
      );

      testWidgets(
        'should allow completing a task',
        (WidgetTester tester) async {
          await pumpAppAndSettle(tester, app);

          await tester.tap(find.widgetWithText(ListTile, task.title));
          await tester.pumpAndSettle();

          await tester.runAsync(() async {
            final taskRecords =
                (await taskListService.getTaskListById(taskList.id!))?.elements;
            expect(taskRecords, isNot(null));
            expect(taskRecords!.length, 1);
            final task = taskRecords.first;
            expect(task.completed, true);
          });
        },
      );

      testWidgets(
        'show checked circle for completed task',
        (WidgetTester tester) async {
          await tester.runAsync(() async {
            await taskListService.upsertTask(
              taskList.id!,
              task..completed = true,
            );
          });
          await pumpAppAndSettle(tester, app);
          final completedTaskIcon =
              (tester.firstWidget(find.byIcon(Icons.check_circle)) as Icon);

          expect(completedTaskIcon.color, Colors.green);
          expect(completedTaskIcon.semanticLabel, 'Completed Task');
        },
      );

      testWidgets(
        'should allow task deletion',
        (WidgetTester tester) async {
          await pumpAppAndSettle(tester, app);

          await findAndSlideWidgetOpen(tester);
          await tester.tap(find.byIcon(Icons.delete));
          await tester.pumpAndSettle();

          await tester.runAsync(() async {
            final tasks =
                (await taskListService.getTaskListById(taskList.id!))?.elements;
            expect(tasks, isEmpty);
          });
        },
      );
    },
  );
}
