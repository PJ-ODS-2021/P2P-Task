import 'package:flutter/material.dart';
import 'package:p2p_task/config/style_constants.dart';
import 'package:p2p_task/services/task_list/activity_record.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/peer_info_service.dart';
import 'package:p2p_task/services/task_list/task_list_service.dart';
import 'package:provider/provider.dart';

import 'activity_entry_widget.dart';

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
    if (activities.isEmpty) return _buildPlaceholder();

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: activities.length,
      itemBuilder: (BuildContext context, int index) => ActivityEntryWidget(
        activities[index],
        currentPeerId,
        deviceNameMap,
        index,
      ),
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
