import 'package:flutter/material.dart';
import 'package:p2p_task/services/task_lists_service.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/widgets/list_section.dart';
import 'package:provider/provider.dart';

class DatabaseSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final taskListsService =
        Provider.of<ChangeCallbackNotifier<TaskListsService>>(context)
            .callbackProvider;

    ListTile _buildListTile(String entries, String title, dynamic textButton) {
      return ListTile(
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
                  textButton,
                ],
              );
            }),
        leading: Icon(Icons.data_usage),
        title: Text(title),
        subtitle: Text(entries),
      );
    }

    return FutureBuilder<List>(
      initialData: ['Loading...', 'Loading...'],
      future: Future.wait([taskListsService.count(), taskListsService.count()]),
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
                          final lists = await taskListsService.lists;
                          lists.forEach((element) {
                            taskListsService.remove(element);
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
              title: Text('Purge list entries'),
              subtitle: Text(listEntries.toString()),
            ),
            _buildListTile(
              listEntries.toString(),
              'Purge task entries',
              TextButton(
                onPressed: () async {
                  final lists = await taskListsService.lists;
                  lists.forEach((element) {
                    taskListsService.remove(element);
                  });
                  Navigator.pop(context);
                },
                child: Text('Yes'),
              ),
            )
          ],
        );
      },
    );
  }
}
