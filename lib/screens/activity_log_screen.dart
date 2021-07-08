import 'package:flutter/material.dart';
import 'package:p2p_task/config/style_constants.dart';
import 'package:p2p_task/services/activity_record.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/peer_info_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ActivityLogScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final taskListService =
        Provider.of<ChangeCallbackNotifier<TaskListService>>(context)
            .callbackProvider;
    final identityService =
        Provider.of<ChangeCallbackNotifier<IdentityService>>(context)
            .callbackProvider;
    final peerInfoService =
        Provider.of<ChangeCallbackNotifier<PeerInfoService>>(context)
            .callbackProvider;

    return FutureBuilder<List>(
      future: Future.wait([
        taskListService.allActivities,
        identityService.peerId,
        peerInfoService.deviceNameMap,
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
        final activities = (data[0] as Iterable<ActivityRecord>).toList();
        activities.sort(_compareActivityRecord);

        return _buildActivityEntries(context, activities, data[1], data[2]);
      },
    );
  }

  Widget _buildActivityEntries(
    BuildContext context,
    List<ActivityRecord> activities,
    String currentPeerId,
    Map<String, String> deviceNameMap,
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

        return _buildActivityEntry(
          activity,
          currentPeerId,
          deviceNameMap,
          index,
        );
      },
    );
  }

  Widget _buildActivityEntry(
    ActivityRecord activity,
    String currentPeerId,
    Map<String, String> deviceNameMap,
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
                  children: [_buildActivityName(activity)],
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    _buildActivityIcon(activity, currentPeerId),
                    const SizedBox(width: 8.0),
                    _buildActivityOrigin(
                      activity.peerId,
                      currentPeerId,
                      deviceNameMap,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [_buildActivityTimestamp(activity.timestamp)],
                ),
              ],
            ),
          ),
        ),
        Container(height: 0.5, color: Colors.grey),
      ],
    );
  }

  Widget _buildActivityName(ActivityRecord activity) {
    return Flexible(
      child: Text(
        _getActivityDescription(activity),
        style: TextStyle(
          fontWeight: FontWeight.normal,
          color: Colors.black,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildActivityTimestamp(DateTime timestamp) {
    return Text(
      DateFormat('dd.MM.yyyy HH:mm:ss').format(timestamp),
      style: TextStyle(
        color: Colors.black.withOpacity(0.6),
        fontSize: 14,
      ),
    );
  }

  Widget _buildActivityIcon(ActivityRecord activity, String currentPeerId) {
    return Icon(activity.peerId == currentPeerId
        ? Icons.arrow_upward
        : Icons.arrow_downward);
  }

  Widget _buildActivityOrigin(
    String peerId,
    String currentPeerId,
    Map<String, String> deviceNameMap,
  ) {
    return Flexible(
      child: RichText(
        text: TextSpan(
          text: 'On ',
          style: TextStyle(color: Colors.black, fontSize: 18),
          children: [
            TextSpan(
              text: _getPeerName(peerId, currentPeerId, deviceNameMap),
              style: TextStyle(
                color: Colors.black,
                fontWeight: peerId == currentPeerId
                    ? FontWeight.normal
                    : FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPeerName(
    String peerId,
    String currentPeerId,
    Map<String, String> deviceNameMap,
  ) {
    return peerId == currentPeerId
        ? 'this device'
        : (deviceNameMap[peerId] ?? peerId);
  }

  String _getActivityDescription(ActivityRecord activity) {
    if (activity is TaskListActivity) {
      return activity.isDeleted
          ? 'Task list deleted'
          : 'Task list created: "${activity.taskList!.title}"';
    } else if (activity is TaskActivity) {
      if (activity.isDeleted) return 'Task deleted';

      return activity.isRecursiveUpdate
          ? 'Task updated: "${activity.task!.title}"'
          : 'Task created: "${activity.task!.title}"';
    }

    return 'Unknown activity in ${activity.id}';
  }

  int _compareActivityRecord(ActivityRecord a, ActivityRecord b) {
    // show most recent first
    var cmp = b.timestamp.compareTo(a.timestamp);
    if (cmp != 0) return cmp;

    // show certain types of activities first
    final activityTypeRankingA = _getActivityTypeRanking(a);
    final activityTypeRankingB = _getActivityTypeRanking(b);
    cmp = activityTypeRankingA.compareTo(activityTypeRankingB);
    if (cmp != 0) return cmp;

    // sort by peer id
    cmp = a.peerId.compareTo(b.peerId);
    if (cmp != 0) return cmp;

    // sort by id
    return a.id.compareTo(b.id);
  }

  int _getActivityTypeRanking(ActivityRecord record) {
    const activityTypes = [TaskActivity, TaskListActivity];
    final ranking = activityTypes.indexOf(record.runtimeType);

    return ranking != -1 ? ranking : activityTypes.length;
  }
}
