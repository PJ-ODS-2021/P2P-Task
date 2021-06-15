import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:p2p_task/models/activity_entry.dart';

class ActivityEntryService extends ChangeNotifier {
  final List<ActivityEntry> _activities = [];

  ActivityEntryService() {
    // ToDo This is only need for debugging reasons.
    //  It should be removed before deployment!
    this.add(ActivityEntry(
        event: "Task Created",
        device: "Windows Phone",
        network: "House Work",
        timestamp: DateTime(2021, 05, 25)));
    this.add(ActivityEntry(
        event: "Task Updated",
        device: "iPad",
        network: "House Work",
        timestamp: DateTime(2021, 06, 02)));
    this.add(ActivityEntry(
        event: "Task Created",
        device: "Windows PC",
        network: "Work",
        timestamp: DateTime(2021, 06, 13)));
    this.add(ActivityEntry(
        event: "Task Completed",
        device: "iPad",
        network: "Work",
        timestamp: DateTime(2021, 06, 14)));
  }

  UnmodifiableListView<ActivityEntry> get activities =>
      UnmodifiableListView(_activities);

  void add(ActivityEntry entry) {
    _activities.add(entry);
    notifyListeners();
  }

  void removeAll() {
    _activities.clear();
    notifyListeners();
  }
}
