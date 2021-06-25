import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/widgets/app_lifecycle_reactor.dart';

void main() {
  testWidgets(
    'Resume lifecycle event should trigger onResume callback',
    (WidgetTester tester) async {
      var ran = false;
      final widget = MaterialApp(
        home: AppLifecycleReactor(
          onResume: () => ran = true,
          child: Text('Let\'s get ready to rumble! 💪'),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pump();

      expect(ran, false);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      expect(ran, true);
    },
  );

  testWidgets(
    'Detached lifecycle event should trigger onDetached callback',
    (WidgetTester tester) async {
      var ran = false;
      final widget = MaterialApp(
        home: AppLifecycleReactor(
          onDetached: () => ran = true,
          child: Text('Where the heck is my charging cable??! ⚡'),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pump();

      expect(ran, false);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.detached);

      expect(ran, true);
    },
  );
}
