import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:p2p_task/config/style_constants.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/models/task_list.dart';
import 'package:p2p_task/screens/task_form_screen.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:provider/provider.dart';
import 'package:p2p_task/widgets/bottom_navigation.dart';
import 'package:intl/intl.dart';

class TaskListScreen extends StatefulWidget {
  final TaskList taskList;
  TaskListScreen(this.taskList);

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  Filter _filter = Filter.Default;

  @override
  Widget build(BuildContext context) {
    final taskListService = Provider.of<TaskListService>(context);

    final futureBuilder = FutureBuilder<List<Task>>(
        initialData: [],
        future: taskListService.getTasksByListID(widget.taskList.id!, _filter),
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (snapshot.hasError)
            return Column(
              children: [
                Text('Error'),
                Text(snapshot.error.toString()),
              ],
            );
          return _buildTaskList(context, taskListService, data!);
        });

    return Scaffold(
      appBar: AppBar(
        // needs leading overwrite or a functional BottomNavigation
        title: Text(widget.taskList.title),
        centerTitle: true,
        actions: [
          _getFilterButton(),
        ],
      ),
      body: Stack(
        alignment: const Alignment(0, 0.9),
        children: [
          futureBuilder,
          ElevatedButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TaskFormScreen(
                          listID: widget.taskList.id!,
                        ))),
            child: Icon(Icons.add),
            style: ElevatedButton.styleFrom(
              shape: CircleBorder(),
              padding: EdgeInsets.all(24),
            ),
          )
        ],
      ),
      // ToDo: onTap
      bottomNavigationBar: BottomNavigation(
        onTap: (index) {},
      ),
    );
  }

  Widget _buildTaskList(
      BuildContext context, TaskListService service, List<Task> tasks) {
    if (tasks.length == 0) {
      return Center(
          child: Column(
        children: [
          Spacer(),
          Text('🎉 Nothing to do.', style: kHeroFont),
          Text('Click the plus button below to add a ToDo.'),
          Spacer(flex: 2),
        ],
      ));
    }
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return _buildSlidableTaskRow(context, service, tasks[index], index);
      },
    );
  }

  Widget _getFilterButton() {
    return IconButton(
      onPressed: () {
        showDialog(
            context: context,
            builder: (context) {
              return SimpleDialog(
                title: Text('Filter by'),
                children: [
                  _getSimpleDialog(Filter.Title),
                  _getSimpleDialog(Filter.Priority),
                  _getSimpleDialog(Filter.Status),
                  _getSimpleDialog(Filter.DueDate),
                ],
              );
            });
      },
      icon: Icon(Icons.filter_alt_sharp),
    );
  }

  SimpleDialogOption _getSimpleDialog(Filter filter) {
    return SimpleDialogOption(
      onPressed: () {
        setState(() {
          _filter = filter;
        });
        Navigator.pop(context);
      },
      child: Text(filter.toString().replaceAll('Filter.', '')),
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
                  builder: (context) => TaskFormScreen(
                        task: task,
                        listID: widget.taskList.id!,
                      ))),
        ),
        IconSlideAction(
          caption: 'Delete',
          color: Colors.red,
          icon: Icons.delete,
          onTap: () => service.remove(task),
        ),
      ],
    );
  }

  Widget _buildTaskContainer(TaskListService service, Task task, int index) {
    String subtitle = task.description ?? '';
    if (subtitle != '') {
      subtitle = subtitle + '\n';
    }
    if (task.due != null) {
      subtitle = subtitle + DateFormat('dd.MM.yyyy hh:mm').format(task.due!);
    }

    return Container(
      color: index.isEven ? Colors.white : Colors.white60,
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            task.completed
                ? Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    semanticLabel: "Completed Task",
                  )
                : Icon(
                    Icons.circle_outlined,
                    semanticLabel: "Uncompleted Task",
                  ),
            SizedBox(
              width: 15,
            ),
            task.priority
                ? Icon(
                    Icons.flag,
                    color: Colors.red,
                    semanticLabel: "High Priority",
                  )
                : Icon(
                    Icons.flag,
                    color: Colors.grey[300],
                    semanticLabel: "Low Priority",
                  ),
          ],
        ),
        title: Text(task.title),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_left),
        onTap: () {
          task.completed = !task.completed;
          service.upsert(task);
        },
        onLongPress: () {
          task.priority = !task.priority;
          service.upsert(task);
        },
      ),
    );
  }
}
