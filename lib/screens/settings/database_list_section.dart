import 'package:flutter/material.dart';
import 'package:p2p_task/services/task_lists_service.dart';
import 'package:p2p_task/screens/setup/landing_screen.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/database_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/widgets/list_section.dart';
import 'package:p2p_task/widgets/yes_no_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final taskListsService =
        Provider.of<ChangeCallbackNotifier<TaskListsService>>(context)
            .callbackProvider;
    final taskListService =
        Provider.of<ChangeCallbackNotifier<TaskListService>>(context)
            .callbackProvider;
    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);
    final sharedPreferences =
        Provider.of<SharedPreferences>(context, listen: false);

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
                          await taskListService.delete();
                          Navigator.pop(context);
                        },
                        child: Text('Yes'),
                      ),
                    ],
                  );
                },
              ),
              leading: Icon(Icons.data_usage),
              title: Text('Delete all Task Lists'),
              subtitle: Text(listEntries.toString()),
            ),
            ListTile(
              tileColor: Colors.white,
              onTap: () => handleDatabaseDeletion(
                context,
                databaseService,
                sharedPreferences,
              ),
              leading: Icon(Icons.delete_forever),
              title: Text('Reset database'),
              subtitle: Text(databaseService.database?.path ?? ''),
            ),
          ],
        );
      },
    );
  }

  void handleDatabaseDeletion(
    BuildContext context,
    DatabaseService databaseService,
    SharedPreferences sharedPreferences,
  ) async {
    final confirmed =
        await YesNoDialog.show(context, title: 'Delete all data?') ?? false;
    if (confirmed) {
      await databaseService.delete();
      await sharedPreferences.clear();
      await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return LandingScreen();
      }));
    }
  }
}
