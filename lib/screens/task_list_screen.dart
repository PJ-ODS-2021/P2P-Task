import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:p2p_task/config/style_constants.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/models/task_list.dart';
import 'package:p2p_task/screens/task_form_screen.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:provider/provider.dart';
import 'package:p2p_task/widgets/bottom_navigation.dart';

class TaskListScreen extends StatefulWidget {
  final TaskList taskList;
  TaskListScreen(this.taskList);

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final taskListService = Provider.of<TaskListService>(context);

    final futureBuilder = FutureBuilder<List<Task>>(
        initialData: [],
        future: taskListService.getTasksByListID(widget.taskList.id!),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Column(
              children: [
                Text('Error'),
                Text(snapshot.error.toString()),
              ],
            );
          return _buildTaskList(context, taskListService, snapshot.data!);
        });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskList.title),
        centerTitle: true,
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
      bottomNavigationBar: BottomNavigation(
        onTap: (index) => setState(() {
          _selectedIndex = index;
        }),
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
    return Container(
      color: index.isEven ? Colors.white : Colors.white60,
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
