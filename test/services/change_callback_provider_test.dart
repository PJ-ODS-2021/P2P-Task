import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/services/change_callback_provider.dart';

void main() {
  group('ChangeCallbackProvider', () {
    test('should invoke change callback', () async {
      final provider = ChangeCallbackProvider();
      final completer = Completer<bool>();
      final callback = () => completer.complete(true);
      provider.addChangeCallback(callback);
      provider.invokeChangeCallback();
      expect(completer.isCompleted, true);
      expect(await completer.future, true);
    });

    test('should not invoke change after removing it', () {
      final provider = ChangeCallbackProvider();
      final completer = Completer<bool>();
      final callback = () => completer.complete(true);
      provider.addChangeCallback(callback);
      provider.removeChangeCallback(callback);
      provider.invokeChangeCallback();
      expect(completer.isCompleted, false);
    });

    test('should invoke multiple callbacks', () async {
      final provider = ChangeCallbackProvider();
      final completers = [
        for (var i = 0; i < 10; i++) Completer<bool>(),
      ];
      final callbacks = completers
          .map((completer) => () => completer.complete(true))
          .toList();
      callbacks.forEach(provider.addChangeCallback);

      provider.invokeChangeCallback();
      completers.forEach((completer) => expect(completer.isCompleted, true));
      expect(
        await Future.wait(completers.map((completer) => completer.future)),
        completers.map((_) => true).toList(),
      );
    });

    test('should invoke multiple callbacks remove some', () async {
      final provider = ChangeCallbackProvider();
      final completers = [
        for (var i = 0; i < 10; i++) Completer<bool>(),
      ];
      final callbacks = completers
          .map((completer) => () => completer.complete(true))
          .toList();
      callbacks.forEach(provider.addChangeCallback);
      for (var i = 0; i < callbacks.length; i++) {
        if (i.isEven) provider.removeChangeCallback(callbacks[i]);
      }

      provider.invokeChangeCallback();

      for (var i = 0; i < completers.length; i++) {
        final completer = completers[i];
        if (i.isEven) {
          expect(completer.isCompleted, false);
        } else {
          expect(completer.isCompleted, true);
          expect(await completer.future, true);
        }
      }
    });
  });
}
