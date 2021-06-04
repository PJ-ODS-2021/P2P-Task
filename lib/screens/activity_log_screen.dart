import 'package:flutter/material.dart';
import 'package:p2p_task/models/activity_entry.dart';
import 'package:p2p_task/services/activity_entry_service.dart';
import 'package:provider/provider.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';

import '../models/activity_entry.dart';

class ActivityLogScreen extends StatefulWidget {
  ActivityLogScreen({Key? key}) : super(key: key);

  @override
  _ActivityLogScreenState createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  final _heroFont = TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold);
  @override
  Widget build(BuildContext context) {
    final activityEntryWidget = Consumer<ActivityEntryService>(
      builder: (context, service, child) =>
          _buildActivityEntries(context, service),
    );
    return activityEntryWidget;
  }

  Widget _buildActivityEntries(
      BuildContext context, ActivityEntryService service) {
    if (service.activities.length == 0) {
      return Center(
          child: Column(
        children: [
          Spacer(),
          Text('⚡️ No activities yet.', style: _heroFont),
          Text('Changes to your Tasks will be shown here.'),
          Text('Create a new Task or pair a device to see some activities.'),
          Spacer(flex: 2),
        ],
      ));
    }
    return ListView.separated(
        padding: EdgeInsets.symmetric(vertical: 8),
        itemCount: service.activities.length,
        separatorBuilder: (BuildContext context, int index) => const Divider(),
        itemBuilder: (BuildContext context, int index) {
          final activity = service.activities[index];
          return _buildActivityEntry(context, activity);
        });
  }

  Widget _buildActivityEntry(BuildContext context, ActivityEntry activity) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
              getActivityIcon(activity),
              const SizedBox(width: 8.0),
              _getActivityDescription(activity),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getActivityName(ActivityEntry activity) {
    return Text(
      activity.event != null ? activity.event : '',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black,
        fontSize: 18,
      ),
    );
  }

  Widget _getActivityDate(ActivityEntry activity) {
    return Text(
      "${activity.timestamp?.day}/${activity.timestamp?.month}/${activity.timestamp?.year}",
      style: TextStyle(
        color: Colors.black.withOpacity(0.6),
        fontSize: 14,
      ),
    );
  }

  Widget getActivityIcon(ActivityEntry activity) {
    return Icon(
      activity.device == "My iPad" ? EvaIcons.upload : EvaIcons.download,
      color: Colors.black,
      size: 22,
    );
  }

  Widget _getActivityDescription(ActivityEntry activity) {
    return RichText(
      text: TextSpan(
        text: "On ",
        style: TextStyle(color: Colors.grey),
        children: [
          TextSpan(
            text: activity.event == "Task Completed"
                ? "this device"
                : activity.device,
            style: TextStyle(
              color: activity.event == "Task Completed"
                  ? Colors.black.withOpacity(0.5)
                  : Colors.black.withOpacity(0.6),
              fontWeight: activity.event == "Task Completed"
                  ? FontWeight.normal
                  : FontWeight.bold,
            ),
          ),
          TextSpan(
            text: " in ",
            style: TextStyle(color: Colors.black.withOpacity(0.5)),
          ),
          TextSpan(
            text: activity.device,
            style: TextStyle(
              color: Colors.black.withOpacity(0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
