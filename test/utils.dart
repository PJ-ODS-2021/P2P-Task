/// Utility functions for testing

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:sembast/sembast.dart' hide Finder;

Future<void> pumpAppAndSettle(WidgetTester tester, Widget app) async {
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

Future<void> slideWidgetOpen(WidgetTester tester, Finder finder) async {
  // If this test fails unexpectedly, the slideOffset is likely wrong.
  // Increase the offset e.g. to Offset(-1000, 0) and rerun the test.
  await tester.drag(finder, const Offset(-500, 0));
  await tester.pumpAndSettle();
}

Future<TaskListService> initTaskListService(Database database) async {
  final keyValueRepository = KeyValueRepository(database, StoreRef(''));
  final identityService = IdentityService(keyValueRepository);
  final syncService = SyncService(keyValueRepository);
  await syncService.setInterval(0);

  return TaskListService(
    keyValueRepository,
    identityService,
    syncService,
  );
}
