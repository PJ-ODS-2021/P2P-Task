import 'package:flutter/material.dart';
import 'package:p2p_task/config/style_constants.dart';
import 'package:p2p_task/models/activity_entry.dart';
import 'package:p2p_task/services/activity_entry_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/activity_entry.dart';

class ActivityLogScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final activityEntryWidget =
        Consumer<ActivityEntryService>(builder: (context, service, child) {
      return FutureBuilder<List<ActivityEntry>>(builder: (context, snapshot) {
        return _buildActivityEntries(context, service);
      });
    });

    return activityEntryWidget;
  }

  Widget _buildActivityEntries(
    BuildContext context,
    ActivityEntryService service,
  ) {
    if (service.activities.isEmpty) {
      return Center(
        child: Column(
          children: [
            Spacer(),
            Text('⚡️ No activities yet.', style: kHeroFont),
            Text('Changes to your Tasks will be shown here.'),
            Text('Create a new Task or pair a device to see some activities.'),
            Spacer(flex: 2),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: service.activities.length,
      itemBuilder: (BuildContext context, int index) {
        final activity = service.activities[index];

        return _buildActivityEntry(context, activity, service, index);
      },
    );
  }

  Widget _buildActivityEntry(
    BuildContext context,
    ActivityEntry activity,
    ActivityEntryService service,
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
                    getActivityIcon(activity, service),
                    const SizedBox(width: 8.0),
                    _getActivityDescription(activity, service),
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

  Widget getActivityIcon(ActivityEntry activity, ActivityEntryService service) {
    return Icon(activity.device == service.getCurrentDeviceName()
        ? Icons.arrow_upward
        : Icons.arrow_downward);
    // return Image.asset(
    //   activity.device == service.getCurrentDeviceName()
    //       ? 'assets/up_arrow_icon.png'
    //       : 'assets/down_arrow_icon.png',
    //   width: 22,
    //   height: 22,
    // );
  }

  Widget _getActivityDescription(
    ActivityEntry activity,
    ActivityEntryService service,
  ) {
    return RichText(
      text: TextSpan(
        text: 'On ',
        style: TextStyle(color: Colors.black, fontSize: 18),
        children: [
          TextSpan(
            text: activity.device == service.getCurrentDeviceName()
                ? 'this device'
                : activity.device,
            style: TextStyle(
              color: Colors.black,
              fontWeight: activity.device == service.getCurrentDeviceName()
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
