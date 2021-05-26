import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:p2p_task/models/activity_entry.dart';

class ActivityEntryService extends ChangeNotifier {
  final List<ActivityEntry> _activities = [];

  ActivityEntryService() {
    // ToDo This is only need for debugging reasons.
    //  It should be removed before deployment!
    this.add(ActivityEntry(event: "Task Created", device: "My iPad"));
    this.add(ActivityEntry(event: "Task Updated", device: "My iPad"));
    this.add(ActivityEntry(event: "Task Created", device: "My MacBook"));
    this.add(ActivityEntry(event: "Task Completed"));
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
