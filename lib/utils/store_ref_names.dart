enum StoreRefNames {
  settings,
  peerInfo,
  tasks,
}

extension Value on StoreRefNames {
  String get value => toString().split('.').last;
}
