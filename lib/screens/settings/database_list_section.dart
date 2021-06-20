import 'package:flutter/material.dart';
import 'package:p2p_task/services/task_lists_service.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/widgets/list_section.dart';
import 'package:provider/provider.dart';

class DatabaseSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final taskListsService =
        Provider.of<ChangeCallbackNotifier<TaskListsService>>(context)
            .callbackProvider;

    return FutureBuilder<int>(
      initialData: -1,
      future: taskListsService.count(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error'),
          );
        }
        final listEntries = snapshot.data!;

        return ListSection(
          title: 'Database',
          children: [
            ListTile(
              tileColor: Colors.white,
              onTap: () => showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Delete all entries?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await taskListsService.delete();
                          Navigator.pop(context);
                        },
                        child: Text('Yes'),
                      ),
                    ],
                  );
                },
              ),
              leading: Icon(Icons.data_usage),
              title: Text('Purge list entries'),
              subtitle: Text(listEntries.toString()),
            ),
          ],
        );
      },
    );
  }
}
