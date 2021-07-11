import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/services/change_callback_provider.dart';

void main() {
  group('ChangeCallbackProvider', () {
    test('should invoke change callback', () {
      final provider = ChangeCallbackProvider();
      var completed = false;
      final callback = () => completed = true;
      provider.addChangeCallback(callback);
      provider.invokeChangeCallback();
      expect(completed, true);
    });

    test('should not invoke change after removing it', () {
      final provider = ChangeCallbackProvider();
      var completed = false;
      final callback = () => completed = true;
      provider.addChangeCallback(callback);
      provider.removeChangeCallback(callback);
      provider.invokeChangeCallback();
      expect(completed, false);
    });

    test('should invoke multiple callbacks', () {
      final provider = ChangeCallbackProvider();
      final completed = List.filled(10, false);
      final callbacks = [
        for (var i = 0; i < completed.length; i++) () => completed[i] = true,
      ];
      callbacks.forEach(provider.addChangeCallback);

      provider.invokeChangeCallback();
      expect(completed, List.filled(completed.length, true));
    });

    test('should invoke multiple callbacks remove some', () async {
      final provider = ChangeCallbackProvider();
      final completed = List.filled(10, false);
      final callbacks = [
        for (var i = 0; i < completed.length; i++) () => completed[i] = true,
      ];
      callbacks.forEach(provider.addChangeCallback);
      for (var i = 0; i < callbacks.length; i++) {
        if (i.isEven) provider.removeChangeCallback(callbacks[i]);
      }

      provider.invokeChangeCallback();

      expect(completed, [
        for (var i = 0; i < completed.length; i++) i.isOdd,
      ]);
    });

    test('should not invoke cleared callbacks', () {
      final provider = ChangeCallbackProvider();
      final completed = List.filled(10, false);
      final callbacks = [
        for (var i = 0; i < completed.length; i++) () => completed[i] = true,
      ];
      callbacks.forEach(provider.addChangeCallback);

      provider.clearChangeCallbacks();
      provider.invokeChangeCallback();
      expect(completed, List.filled(completed.length, false));
    });
  });
}
