import 'package:flutter/material.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/widgets/list_section.dart';
import 'package:provider/provider.dart';

class DatabaseListSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final taskListService =
        Provider.of<ChangeCallbackNotifier<TaskListService>>(context)
            .callbackProvider;

    return FutureBuilder<int>(
      initialData: -1,
      future: taskListService.count(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error'),
          );
        }
        final taskEntries = snapshot.data!;

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
                          final tasks = await taskListService.tasks;
                          tasks.forEach((element) {
                            taskListService.remove(element);
                          });
                          Navigator.pop(context);
                        },
                        child: Text('Yes'),
                      ),
                    ],
                  );
                },
              ),
              leading: Icon(Icons.data_usage),
              title: Text('Purge task entries'),
              subtitle: Text(taskEntries.toString()),
            ),
          ],
        );
      },
    );
  }
}
