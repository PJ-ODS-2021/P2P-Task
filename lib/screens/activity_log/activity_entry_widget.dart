import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:p2p_task/services/task_list/activity_record.dart';

class ActivityEntryWidget extends StatelessWidget {
  final ActivityRecord activity;
  final String currentPeerId;
  final Map<String, String> deviceNameMap;
  final int index;

  const ActivityEntryWidget(
    this.activity,
    this.currentPeerId,
    this.deviceNameMap,
    this.index,
  );

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
      if (activity.isPropertyUpdate) {
        return Icon(Icons.refresh, semanticLabel: 'Updated Task List');
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
              text: _peerName,
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

  String get _peerName => activity.peerId == currentPeerId
      ? 'this device'
      : (deviceNameMap[activity.peerId] ?? activity.peerId);
}
