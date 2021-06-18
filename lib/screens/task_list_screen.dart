import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:p2p_task/config/style_constants.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/screens/task_form_screen.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:provider/provider.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';

class TaskListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final taskListService =
        Provider.of<ChangeCallbackNotifier<TaskListService>>(context)
            .callbackProvider;

    final futureBuilder = FutureBuilder<List<Task>>(
      initialData: [],
      future: taskListService.tasks,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            children: [
              Text('Error'),
              Text(snapshot.error.toString()),
            ],
          );
        }

        return _buildTaskList(context, taskListService, snapshot.data!);
      },
    );

    return Stack(
      alignment: const Alignment(0, 0.9),
      children: [
        futureBuilder,
        ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TaskFormScreen()),
          ),
          style: ElevatedButton.styleFrom(
            shape: CircleBorder(),
            padding: EdgeInsets.all(24),
          ),
          child: Icon(Icons.add),
        ),
      ],
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    TaskListService service,
    List<Task> tasks,
  ) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          children: [
            Spacer(),
            Text('🎉 Nothing to do.', style: kHeroFont),
            Text('Click the plus button below to add a ToDo.'),
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
          service,
          tasks[index],
          index,
        );
      },
    );
  }

  Widget _buildSlidableTaskRow(
    BuildContext context,
    TaskListService service,
    Task task,
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
              builder: (context) => TaskFormScreen(task: task),
            ),
          ),
        ),
        IconSlideAction(
          caption: 'Delete',
          color: Colors.red,
          icon: Icons.delete,
          onTap: () => service.remove(task),
        ),
      ],
      child: _buildTaskContainer(service, task, index),
    );
  }

  Widget _buildTaskContainer(TaskListService service, Task task, int index) {
    return Container(
      color: index.isEven ? Colors.white : Colors.white60,
      child: ListTile(
        leading: task.completed
            ? const Icon(
                Icons.check_circle,
                color: Colors.green,
                semanticLabel: 'Completed Task',
              )
            : const Icon(
                EvaIcons.radioButtonOffOutline,
                semanticLabel: 'Uncompleted Task',
              ),
        title: Text(task.title),
        subtitle: Text(task.description ?? ''),
        trailing: Icon(Icons.chevron_left),
        onTap: () {
          task.completed = !task.completed;
          service.upsert(task);
        },
      ),
    );
  }
}
