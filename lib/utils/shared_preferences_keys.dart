enum SharedPreferencesKeys {
  databasePath,
  inMemory,
}

extension Value on SharedPreferencesKeys {
  String get value => toString().split('.').last;
}
