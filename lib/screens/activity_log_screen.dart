import 'package:flutter/material.dart';
import 'package:p2p_task/models/activity_entry.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/activity_entry.dart';

class ActivityLogScreen extends StatelessWidget {
  final _heroFont = TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold);

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
        taskListService.allTaskRecords.then((v) => _getActivityEntries(v)),
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

        return _buildActivityEntries(context, data[0], data[1]);
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
            Text('⚡️ No activities yet.', style: _heroFont),
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
                    _getActivityName(activity),
                    _getActivityDate(activity),
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    getActivityIcon(activity, currentPeerId),
                    const SizedBox(width: 8.0),
                    _getActivityDescription(activity, currentPeerId),
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

  Widget _getActivityName(ActivityEntry activity) {
    return Text(
      activity.event.isNotEmpty ? activity.event : '',
      style: TextStyle(
        fontWeight: FontWeight.normal,
        color: Colors.black,
        fontSize: 18,
      ),
    );
  }

  Widget _getActivityDate(ActivityEntry activity) {
    return Text(
      DateFormat('dd.MM.yyyy').format(activity.timestamp!),
      style: TextStyle(
        color: Colors.black.withOpacity(0.6),
        fontSize: 14,
      ),
    );
  }

  Widget getActivityIcon(ActivityEntry activity, String currentPeerId) {
    return Image.asset(
      activity.device == currentPeerId
          ? 'assets/up_arrow_icon.png'
          : 'assets/down_arrow_icon.png',
      width: 22,
      height: 22,
    );
  }

  Widget _getActivityDescription(
    ActivityEntry activity,
    String currentPeerId,
  ) {
    return RichText(
      text: TextSpan(
        text: 'On ',
        style: TextStyle(color: Colors.black, fontSize: 18),
        children: [
          TextSpan(
            text: activity.device == currentPeerId
                ? 'this device'
                : activity.device,
            style: TextStyle(
              color: Colors.black,
              fontWeight: activity.device == currentPeerId
                  ? FontWeight.normal
                  : FontWeight.bold,
              fontSize: 18,
            ),
          ),
          TextSpan(
            text: ' in ',
            style: TextStyle(color: Colors.black, fontSize: 18),
          ),
          TextSpan(
            text: activity.peerInfoID,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  List<ActivityEntry> _getActivityEntries(
    Iterable<TaskRecord> taskEntries,
  ) {
    return taskEntries
        .map((taskEntry) => ActivityEntry(
              event: taskEntry.task == null ? 'Task deleted' : 'Task updated',
              device: taskEntry.peerId,
              taskID: taskEntry.task?.id,
              taskListID: taskEntry.taskListId,
              timestamp: taskEntry.timestamp,
            ))
        .toList()
          ..sort((a, b) => b.timestamp!.compareTo(a.timestamp!));
  }
}
