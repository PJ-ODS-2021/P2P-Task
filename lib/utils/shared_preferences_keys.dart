enum SharedPreferencesKeys {
  databasePath,
  inMemory,
  activateServer,
}

extension Value on SharedPreferencesKeys {
  String get value => toString().split('.').last;
}
