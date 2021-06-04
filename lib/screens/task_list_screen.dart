import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/screens/task_form_screen.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:provider/provider.dart';

class TaskListScreen extends StatefulWidget {
  TaskListScreen({Key? key}) : super(key: key);

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _heroFont = TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    final consumerWidget = Consumer<TaskListService>(
      builder: (context, service, child) => _buildTaskList(context, service),
    );

    return Stack(
      alignment: const Alignment(0, 0.9),
      children: [
        consumerWidget,
        ElevatedButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => TaskFormScreen())),
          child: Icon(Icons.add),
          style: ElevatedButton.styleFrom(
            shape: CircleBorder(),
            padding: EdgeInsets.all(24),
          ),
        )
      ],
    );
  }

  Widget _buildTaskList(BuildContext context, TaskListService service) {
    if (service.tasks.length == 0) {
      return Center(
          child: Column(
        children: [
          Spacer(),
          Text('🎉 Nothing to do.', style: _heroFont),
          Text('Click the plus button below to add a ToDo.'),
          Spacer(flex: 2),
        ],
      ));
    }
    return ListView.builder(
      itemCount: service.tasks.length,
      itemBuilder: (context, index) {
        return _buildSlidableTaskRow(
            context, service, service.tasks[index], index);
      },
    );
  }

  Widget _buildSlidableTaskRow(
      BuildContext context, TaskListService service, Task task, int index) {
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.20,
      child: _buildTaskContainer(service, task, index),
      secondaryActions: <Widget>[
        IconSlideAction(
          caption: 'Edit',
          color: Colors.grey[400],
          icon: Icons.edit,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => TaskFormScreen(task: task))),
        ),
        IconSlideAction(
          caption: 'Delete',
          color: Colors.red,
          icon: Icons.delete,
          onTap: () =>
              Provider.of<TaskListService>(context, listen: false).remove(task),
        ),
      ],
    );
  }

  Widget _buildTaskContainer(TaskListService service, Task task, int index) {
    return Container(
      color: index.isEven ? Colors.white : Colors.white30,
      child: ListTile(
        leading: task.completed
            ? Icon(
                Icons.check_circle,
                color: Colors.green,
                semanticLabel: "Completed Task",
              )
            : Icon(
                Icons.circle_outlined,
                semanticLabel: "Uncompleted Task",
              ),
        title: Text(task.title),
        // ToDo Change subtitle to task description
        subtitle: Text(task.title),
        trailing: Icon(Icons.chevron_left),
        onTap: () {
          setState(() {
            task.completed = !task.completed;
            service.upsert(task);
          });
        },
      ),
    );
  }
}