import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:p2p_task/config/style_constants.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/models/task_list.dart';
import 'package:p2p_task/screens/task_form_screen.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:p2p_task/services/task_lists_service.dart';

class TaskListScreen extends StatefulWidget {
  final TaskList taskList;
  TaskListScreen(this.taskList);

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  Widget build(BuildContext context) {
    final taskListService =
        Provider.of<ChangeCallbackNotifier<TaskListService>>(context)
            .callbackProvider;

    final futureBuilder = FutureBuilder<List<Task>>(
      initialData: [],
      future: taskListService.getTasksForList(widget.taskList),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (snapshot.hasError) {
          return Column(
            children: [
              Text('Error'),
              Text(snapshot.error.toString()),
            ],
          );
        }

        return _buildTaskList(context, taskListService, data!);
      },
    );

    return Scaffold(
      appBar: AppBar(
        // needs functional BottomNavigation
        title: Text(widget.taskList.title),
        centerTitle: true,
        actions: [
          _getSortButton(),
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
                  taskListID: widget.taskList.id!,
                ),
              ),
            ),
            style: ElevatedButton.styleFrom(
              shape: CircleBorder(),
              padding: EdgeInsets.all(24),
            ),
            child: Icon(Icons.add),
          ),
        ],
      ),
      // ToDo: onTap
      // bottomNavigationBar: BottomNavigation(
      //   onTap: (index) {},
      // ),
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
            Text('🎉 Nothing to do.', style: heroFont),
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

  Widget _getSortButton() {
    return IconButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            return SimpleDialog(
              title: Text('Sort tasks by'),
              children: [
                _getSortOption(SortOption.Title),
                _getSortOption(SortOption.Flag),
                _getSortOption(SortOption.Status),
                _getSortOption(SortOption.DueDate),
                _getSortOption(SortOption.Created),
              ],
            );
          },
        );
      },
      icon: Icon(Icons.swap_vert),
    );
  }

  SimpleDialogOption _getSortOption(SortOption sortOption) {
    return SimpleDialogOption(
      onPressed: () {
        setState(() {
          widget.taskList.sortBy = sortOption;
          final listService =
              Provider.of<ChangeCallbackNotifier<TaskListsService>>(
            context,
            listen: false,
          ).callbackProvider;
          listService.upsert(widget.taskList);
        });
        Navigator.pop(context);
      },
      child: Text(getFilterName(sortOption, widget.taskList.sortBy)),
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
              builder: (context) => TaskFormScreen(
                task: task,
                taskListID: widget.taskList.id!,
              ),
            ),
          ),
        ),
        IconSlideAction(
          caption: 'Flag',
          color: Colors.red[900],
          icon: Icons.flag,
          onTap: () {
            task.isFlagged = !task.isFlagged;
            service.upsert(task);
          },
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
    var subtitle = task.description ?? '';
    if (subtitle != '' && task.due != null) {
      subtitle = subtitle + '\n';
    }
    if (task.due != null) {
      subtitle = subtitle + DateFormat('dd.MM.yyyy HH:mm').format(task.due!);
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
                    semanticLabel: 'Completed Task',
                  )
                : Icon(
                    Icons.circle_outlined,
                    semanticLabel: 'Uncompleted Task',
                  ),
            SizedBox(
              width: 15,
            ),
            task.isFlagged
                ? Icon(
                    Icons.flag,
                    color: Colors.red,
                    semanticLabel: 'High Priority',
                  )
                : Icon(
                    Icons.flag,
                    color: index.isEven ? Colors.white : Colors.white60,
                    semanticLabel: 'Low Priority',
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
      ),
    );
  }
}
