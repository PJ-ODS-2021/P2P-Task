import 'package:p2p_task/models/task_list.dart';
import 'package:uuid/uuid.dart';

class ActivityEntry {
  String? id;
  DateTime? timestamp;
  final String event;
  final String? device;
  final String? network;
  final TaskList? list;

  ActivityEntry(
      {this.id,
      this.timestamp,
      this.event = "",
      this.device,
      this.network,
      this.list}) {
    if (this.id == null) this.id = Uuid().v4();
    if (this.timestamp == null) this.timestamp = DateTime.now();
  }
}
