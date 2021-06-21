import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:p2p_task/config/style_constants.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/models/task_list.dart';
import 'package:p2p_task/screens/task_list_screen.dart';
import 'package:p2p_task/screens/task_list_form_screen.dart';
import 'package:p2p_task/services/task_lists_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:provider/provider.dart';

class TaskListsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final listService =
        Provider.of<ChangeCallbackNotifier<TaskListsService>>(context)
            .callbackProvider;
    final taskService =
        Provider.of<ChangeCallbackNotifier<TaskListService>>(context)
            .callbackProvider;

    final futureBuilder = FutureBuilder<List<TaskList>>(
      initialData: [],
      future: listService.lists,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            children: [
              Text('Error'),
              Text(snapshot.error.toString()),
            ],
          );
        }

        return _buildTaskList(
          context,
          listService,
          taskService,
          snapshot.data!,
        );
      },
    );

    return Stack(
      alignment: const Alignment(0, 0.9),
      children: [
        futureBuilder,
        ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskListFormScreen(),
            ),
          ),
          style: ElevatedButton.styleFrom(
            shape: CircleBorder(),
            padding: EdgeInsets.all(24),
          ),
          child: Icon(Icons.add),
        )
      ],
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    TaskListsService listService,
    TaskListService taskService,
    List<TaskList> tasks,
  ) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          children: [
            Spacer(),
            Text('🔥 Start getting productive.', style: kHeroFont),
            Text('Click the plus button below to add a list.'),
            Spacer(flex: 2),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return _buildSlidableTaskRow(
          context,
          listService,
          taskService,
          tasks[index],
          index,
        );
      },
    );
  }

  Widget _buildSlidableTaskRow(
    BuildContext context,
    TaskListsService listService,
    TaskListService taskService,
    TaskList taskList,
    int index,
  ) {
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.20,
      secondaryActions: <Widget>[
        IconSlideAction(
          caption: 'Edit',
          color: Colors.grey[400],
          icon: Icons.edit,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskListFormScreen(
                taskList: taskList,
              ),
            ),
          ),
        ),
        IconSlideAction(
          caption: 'Delete',
          color: Colors.red,
          icon: Icons.delete,
          onTap: () {
            taskService.removeByListID(taskList.id!);
            listService.remove(taskList);
          },
        ),
      ],
      child: _buildTaskListContainer(context, taskList, index),
    );
  }

  Widget _buildTaskListContainer(
    BuildContext context,
    TaskList taskList,
    int index,
  ) {
    return Container(
      color: index.isEven ? Colors.white : Colors.white30,
      child: ListTile(
        leading: Icon(taskList.isShared ? Icons.people : Icons.lock),
        title: Text(taskList.title),
        //toDo add shared with
        trailing: Icon(Icons.chevron_left),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TaskListScreen(taskList)),
        ),
      ),
    );
  }
}
