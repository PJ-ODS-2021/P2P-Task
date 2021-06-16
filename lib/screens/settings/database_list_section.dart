import 'package:flutter/material.dart';
import 'package:p2p_task/services/task_lists_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/widgets/list_section.dart';
import 'package:provider/provider.dart';

class DatabaseSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final taskListsService = Provider.of<TaskListsService>(context);
    final taskListService = Provider.of<TaskListService>(context);

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
      future: Future.wait([taskListsService.count(), taskListService.count()]),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(
            child: Text('Error'),
          );
        final data = snapshot.data!;
        final lists = data[0] ?? 'Unknown';
        final tasks = data[1] ?? 'Unknown';
        return ListSection(
          title: 'Database',
          children: [
            _buildListTile(
              lists.toString(),
              'Purge list entries',
              TextButton(
                onPressed: () async {
                  final lists = await taskListsService.lists;
                  lists.forEach((element) {
                    taskListService.removeByListID(element.id!);
                    taskListsService.remove(element);
                  });
                  Navigator.pop(context);
                },
                child: Text('Yes'),
              ),
            ),
            _buildListTile(
              tasks.toString(),
              'Purge task entries',
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
            )
          ],
        );
      },
    );
  }
}
