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
  @override
  Widget build(BuildContext context) {
    return Consumer<TaskListService>(
        builder: (context, taskListService, child) {
      return ListView(
        children: taskListService.tasks
            .map((element) =>
                _buildSlideable(context, element))
            .toList(),
      );
    });
  }

  Widget _buildSlideable(BuildContext context, Task task) {
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.20,
      child: Container(
        color: Colors.white,
        child: ListTile(
          leading: task.completed ? Icon(Icons.check_box_outlined) : Icon(Icons.check_box_outline_blank),
          title: Text(task.title),
          subtitle: Text(task.title),
        ),
      ),
      secondaryActions: <Widget>[
        IconSlideAction(
          caption: 'Edit',
          color: Colors.grey[400],
          icon: Icons.edit,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TaskFormScreen(task: task))),
        ),
        IconSlideAction(
          caption: 'Delete',
          color: Colors.red,
          icon: Icons.delete,
          onTap: () => Provider.of<TaskListService>(context, listen: false).remove(task),
        ),
      ],
    );
  }
}
