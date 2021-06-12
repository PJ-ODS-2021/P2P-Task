class ChangeCallbackProvider {
  Function()? changeCallback;

  void invokeChangeCallback() {
    if (changeCallback != null) changeCallback!();
  }
}
