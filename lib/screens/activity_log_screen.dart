import 'package:flutter/material.dart';
import 'package:p2p_task/models/activity_entry.dart';
import 'package:p2p_task/services/activity_entry_service.dart';
import 'package:provider/provider.dart';

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
    if (service.activities.isEmpty) {
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
    return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: service.activities.length,
        // separatorBuilder: (BuildContext context, int index) => const Divider(),
        itemBuilder: (BuildContext context, int index) {
          final activity = service.activities[index];
          return _buildActivityEntry(context, activity);
        });
  }

  Widget _buildActivityEntry(BuildContext context, ActivityEntry activity) {
    return Column(
      children: [
        Container(
          color: Color(0xFFe8d8e0),
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
                    getActivityIcon(activity),
                    const SizedBox(width: 8.0),
                    _getActivityDescription(activity),
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
      '${activity.timestamp?.day}/${activity.timestamp?.month}/${activity.timestamp?.year}',
      style: TextStyle(
        color: Colors.black.withOpacity(0.6),
        fontSize: 14,
      ),
    );
  }

  Widget getActivityIcon(ActivityEntry activity) {
    return Image.asset(
        activity.device == 'Windows Phone'
            ? 'assets/up_arrow_icon.png'
            : 'assets/down_arrow_icon.png',
        width: 22,
        height: 22);
  }

  Widget _getActivityDescription(ActivityEntry activity) {
    return RichText(
      text: TextSpan(
        text: 'On ',
        style: TextStyle(color: Colors.black, fontSize: 18),
        children: [
          TextSpan(
            text: activity.device == 'Windows Phone'
                ? 'this device'
                : activity.device,
            style: TextStyle(
              color: Colors.black,
              fontWeight: activity.device == 'Windows Phone'
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
}
