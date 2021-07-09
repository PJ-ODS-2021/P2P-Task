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
      return _buildPlaceholder();
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: activities.length,
      itemBuilder: (BuildContext context, int index) {
        final activity = activities[index];

        return ActivityEntryWidget(
          activity,
          currentPeerId,
          deviceNameMap,
          index,
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        children: [
          Spacer(),
          Text('⚡️ No activities yet.', style: heroFont),
          Text(
            'Changes to your Tasks will be shown here.',
            textAlign: TextAlign.center,
          ),
          Text(
            'Create a new Task or pair a device to see some activities.',
            textAlign: TextAlign.center,
          ),
          Spacer(flex: 2),
        ],
      ),
    );
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

class ActivityEntryWidget extends StatelessWidget {
  const ActivityEntryWidget(
    this.activity,
    this.currentPeerId,
    this.deviceNameMap,
    this.index,
  );

  final ActivityRecord activity;
  final String currentPeerId;
  final Map<String, String> deviceNameMap;
  final int index;

  @override
  Widget build(BuildContext context) {
    return _buildActivityColumn(context);
  }

  Widget _buildActivityColumn(BuildContext context) {
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
                    _buildActivityOrigin(),
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    _buildActivityIcon(activity),
                    const SizedBox(width: 8.0),
                    _buildActivityName(),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [_buildActivityTimestamp()],
                ),
              ],
            ),
          ),
        ),
        Container(height: 0.5, color: Colors.grey),
      ],
    );
  }

  Widget _buildActivityName() {
    return Flexible(
      child: Text(
        activity.description,
        style: TextStyle(
          fontWeight: FontWeight.normal,
          color: Colors.black,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildActivityTimestamp() {
    return Text(
      DateFormat('dd.MM.yyyy HH:mm:ss').format(activity.timestamp),
      style: TextStyle(
        color: Colors.black.withOpacity(0.6),
        fontSize: 14,
      ),
    );
  }

  Icon _buildActivityIcon(ActivityRecord activity) {
    if (activity is TaskActivity) {
      if (activity.isDeleted) {
        return Icon(Icons.delete, semanticLabel: 'Deleted Task');
      }
      if (activity.isRecursiveUpdate) {
        return Icon(Icons.refresh, semanticLabel: 'Updated Task');
      }

      return Icon(Icons.add, semanticLabel: 'New Task');
    }
    if (activity is TaskListActivity) {
      if (activity.isDeleted) {
        return Icon(Icons.delete, semanticLabel: 'Deleted Task List');
      }

      return Icon(Icons.add, semanticLabel: 'New Task List');
    }

    return Icon(Icons.help, semanticLabel: 'Unspecified Activity');
  }

  Widget _buildActivityOrigin() {
    return Flexible(
      child: RichText(
        text: TextSpan(
          text: 'On ',
          style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 18),
          children: [
            TextSpan(
              text: _getPeerName(),
              style: TextStyle(
                color: Colors.black.withOpacity(0.6),
                fontWeight: activity.peerId == currentPeerId
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

  String _getPeerName() {
    final peerId = activity.peerId;

    return peerId == currentPeerId
        ? 'this device'
        : (deviceNameMap[peerId] ?? peerId);
  }
}
