import 'package:flutter/material.dart';
import 'package:p2p_task/models/activity_entry.dart';
import 'package:p2p_task/services/activity_entry_service.dart';
import 'package:provider/provider.dart';

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
        itemCount: service.activities.length,
        separatorBuilder: (BuildContext context, int index) => const Divider(),
        itemBuilder: (BuildContext context, int index) {
          final activity = service.activities[index];
          return _buildActivityEntry(context, activity);
        });
  }

  Widget _buildActivityEntry(BuildContext context, ActivityEntry activity) {
    return ListTile(
      title: Text(activity.event),
      subtitle: Text("On this device in Work."),
      leading: Icon(Icons.file_download_outlined),
      trailing: Text("2021-05-26"),
    );
  }
}
