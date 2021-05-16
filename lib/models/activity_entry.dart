class ActivityEntry {
  final String id;
  final DateTime timestamp;
  final String event;
  final String device;
  final String network;

  ActivityEntry(this.id, this.timestamp, this.event, this.device, this.network);
}