import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:p2p_task/models/activity_entry.dart';

class ActivityEntryService extends ChangeNotifier {
  final List<ActivityEntry> _activities = [];

  ActivityEntryService() {
    // ToDo This is only need for debugging reasons.
    //  It should be removed before deployment!
    add(ActivityEntry(
        event: 'Task Created',
        device: 'Windows Phone',
        peerInfoID: 'House Work',
        taskID: '1',
        timestamp: DateTime(2021, 05, 25)));
    add(ActivityEntry(
        event: 'Description Updated',
        device: 'iPad',
        peerInfoID: 'House Work',
        taskID: '2',
        timestamp: DateTime(2021, 05, 30)));
    add(ActivityEntry(
        event: 'Task Updated',
        device: 'iPhone',
        peerInfoID: 'Work',
        taskListID: '3',
        timestamp: DateTime(2021, 06, 05)));
    add(ActivityEntry(
        event: 'Task List Created',
        device: 'Windows PC',
        peerInfoID: 'Work',
        taskListID: '1',
        timestamp: DateTime(2021, 06, 10)));
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
