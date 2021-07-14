/// Utility functions for testing

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget buildAppWithScreen(
  Widget screen, [
  List<ChangeNotifierProvider> providers = const [],
]) {
  final app = MultiProvider(
    providers: providers,
    child: MaterialApp(
      home: Scaffold(
        body: screen,
      ),
    ),
  );

  return app;
}

void expectSlideActionWith(IconData icon, String caption) {
  final slideAction = find.byType(IconSlideAction);
  final actionIcon = find.descendant(
    of: slideAction,
    matching: find.byIcon(icon),
  );
  final actionCaption = find.descendant(
    of: slideAction,
    matching: find.text(caption),
  );
  // ToDo: This does not ensure that the icon and the caption are from the same
  //  slide action. The test would pass if one slideAction has the icon, but
  // another slideAction has the caption.
  expect(actionIcon, findsOneWidget);
  expect(actionCaption, findsOneWidget);
}

Future<void> findAndSlideWidgetOpen(WidgetTester tester) async {
  final slidable = find.byType(Slidable);
  expect(slidable, findsOneWidget);
  await slideWidgetOpen(tester, slidable);
}

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
