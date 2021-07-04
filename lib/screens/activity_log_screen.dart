import 'package:flutter/material.dart';
import 'package:p2p_task/config/style_constants.dart';
import 'package:p2p_task/models/activity_entry.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/activity_entry.dart';

class ActivityLogScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final taskListService =
        Provider.of<ChangeCallbackNotifier<TaskListService>>(context)
            .callbackProvider;
    final identityService =
        Provider.of<ChangeCallbackNotifier<IdentityService>>(context)
            .callbackProvider;

    return FutureBuilder<List>(
      future: Future.wait([
        taskListService.allActivities
            .then((activities) => _transformActivities(activities).toList()),
        identityService.peerId,
      ]),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            children: [
              Text('Error'),
              Text(snapshot.error.toString()),
            ],
          );
        }
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;

        final activities = data[0] as List<ActivityEntry>;
        activities.sort(_activityEntryCompare);

        return _buildActivityEntries(context, activities, data[1]);
      },
    );
  }

  Widget _buildActivityEntries(
    BuildContext context,
    List<ActivityEntry> activities,
    String currentPeerId,
  ) {
    if (activities.isEmpty) {
      return Center(
        child: Column(
          children: [
            Spacer(),
            Text('⚡️ No activities yet.', style: heroFont),
            Text('Changes to your Tasks will be shown here.'),
            Text('Create a new Task or pair a device to see some activities.'),
            Spacer(flex: 2),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: activities.length,
      itemBuilder: (BuildContext context, int index) {
        final activity = activities[index];

        return _buildActivityEntry(context, activity, currentPeerId, index);
      },
    );
  }

  Widget _buildActivityEntry(
    BuildContext context,
    ActivityEntry activity,
    String currentPeerId,
    int index,
  ) {
    return Column(
      children: [
        Container(
          color: index.isEven ? Colors.white : Colors.white60,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _makeActivityName(activity),
                    _makeActivityDate(activity),
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    _makeActivityIcon(activity, currentPeerId),
                    const SizedBox(width: 8.0),
                    _makeActivityDescription(activity, currentPeerId),
                  ],
                ),
                const SizedBox(height: 8.0),
              ],
            ),
          ),
        ),
        Container(height: 0.5, color: Colors.grey),
      ],
    );
  }

  Widget _makeActivityName(ActivityEntry activity) {
    return Text(
      _getActivityDescriptionStr(activity),
      style: TextStyle(
        fontWeight: FontWeight.normal,
        color: Colors.black,
        fontSize: 18,
      ),
    );
  }

  Widget _makeActivityDate(ActivityEntry activity) {
    return Text(
      DateFormat('dd.MM.yyyy HH:mm:ss').format(activity.timestamp),
      style: TextStyle(
        color: Colors.black.withOpacity(0.6),
        fontSize: 14,
      ),
    );
  }

  Widget _makeActivityIcon(ActivityEntry activity, String currentPeerId) {
    return Icon(activity.peerID == currentPeerId
        ? Icons.arrow_upward
        : Icons.arrow_downward);
  }

  Widget _makeActivityDescription(
    ActivityEntry activity,
    String currentPeerId,
  ) {
    return RichText(
      text: TextSpan(
        text: 'On ',
        style: TextStyle(color: Colors.black, fontSize: 18),
        children: [
          TextSpan(
            text: activity.peerID == currentPeerId
                ? 'this device'
                : activity.peerID,
            style: TextStyle(
              color: Colors.black,
              fontWeight: activity.peerID == currentPeerId
                  ? FontWeight.normal
                  : FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Iterable<ActivityEntry> _transformActivities(
    Iterable<ActivityRecord> activities,
  ) {
    return activities
        .map((activity) => activity is TaskListActivity
            ? _transformListActivity(activity)
            : (activity is TaskActivity
                ? _transformTaskActivity(activity)
                : null))
        .where((activity) => activity != null)
        .map((activity) => activity!);
  }

  ActivityEntry _transformListActivity(TaskListActivity activity) {
    return ActivityEntry(
      peerID: activity.peerId,
      type: activity.taskList != null
          ? ActivityType.Created
          : ActivityType.Deleted,
      timestamp: activity.timestamp,
      name: activity.taskList != null ? activity.taskList!.title : '',
      taskID: null,
      taskListID: activity.id,
    );
  }

  ActivityEntry _transformTaskActivity(TaskActivity activity) {
    return ActivityEntry(
      peerID: activity.peerId,
      type: activity.isRecursiveUpdate
          ? ActivityType.Updated
          : (activity.task != null
              ? ActivityType.Created
              : ActivityType.Deleted),
      timestamp: activity.timestamp,
      name: activity.task != null ? activity.task!.title : '',
      taskID: activity.id,
      taskListID: activity.taskListId,
    );
  }

  String _getActivityDescriptionStr(ActivityEntry activityEntry) {
    final entity = activityEntry.isTaskActivity ? 'Task' : 'Task list';
    final suffix = activityEntry.name.isEmpty ? '' : ': ${activityEntry.name}';
    switch (activityEntry.type) {
      case ActivityType.Created:
        return '$entity created$suffix';
      case ActivityType.Updated:
        return '$entity updated$suffix';
      case ActivityType.Deleted:
        return '$entity deleted$suffix';
      default:
        return '$entity$suffix';
    }
  }

  /// Compares timestamp (descending), isTaskActivity, taskListID, peerID, taskID
  int _activityEntryCompare(ActivityEntry a, ActivityEntry b) {
    var cmp = b.timestamp.compareTo(a.timestamp);
    if (cmp != 0) return cmp;
    if (a.isTaskActivity != b.isTaskActivity) {
      return a.isTaskActivity ? -1 : 1;
    }
    cmp = a.taskListID!.compareTo(b.taskListID!);
    if (cmp != 0) return cmp;
    cmp = a.peerID.compareTo(b.peerID);
    if (cmp != 0 || a.taskID == null) return cmp;

    return a.taskID!.compareTo(b.taskID!);
  }
}
