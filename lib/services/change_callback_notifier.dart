import 'package:flutter/foundation.dart';
import 'package:p2p_task/services/change_callback_provider.dart';

class ChangeCallbackNotifier<T extends ChangeCallbackProvider>
    extends ChangeNotifier {
  final T callbackProvider;

  ChangeCallbackNotifier(this.callbackProvider) {
    callbackProvider.addChangeCallback(notifyListeners);
  }

  @override
  void dispose() {
    callbackProvider.removeChangeCallback(notifyListeners);
    super.dispose();
  }
}
