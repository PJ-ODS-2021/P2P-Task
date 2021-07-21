class ChangeCallbackProvider {
  final _changeCallbacks = <void Function()>[];

  void addChangeCallback(void Function() callback) {
    _changeCallbacks.add(callback);
  }

  bool removeChangeCallback(void Function() callback) {
    return _changeCallbacks.remove(callback);
  }

  void clearChangeCallbacks() {
    _changeCallbacks.clear();
  }

  void invokeChangeCallback() {
    _changeCallbacks.forEach((callback) => callback());
  }
}
