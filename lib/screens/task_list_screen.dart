import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:p2p_task/config/style_constants.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/models/task_list.dart';
import 'package:p2p_task/screens/task_form_screen.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/widgets/pull_to_sync_widget.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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
    final taskListId = widget.taskList.id!;

    final futureBuilder = FutureBuilder<TaskList?>(
      initialData: null,
      future: taskListService.getTaskListById(taskListId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            children: [
              Text('Error'),
              Text(snapshot.error.toString()),
            ],
          );
        }
        final taskList = snapshot.data;
        final tasks = taskList != null
            ? _sortTasks(taskList.sortBy, taskList.elements)
            : <Task>[];

        return _buildTaskList(context, taskListService, tasks);
      },
    );

    return Scaffold(
      appBar: AppBar(
        // needs functional BottomNavigation
        title: Text(widget.taskList.title),
        centerTitle: true,
        actions: [
          _getSortButton(taskListService),
        ],
      ),
      body: Stack(
        alignment: const Alignment(0, 0.9),
        children: [
          futureBuilder,
          ElevatedButton(
            key: Key('addTaskButton'),
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
            child: Icon(Icons.add, semanticLabel: 'Add task'),
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
      final oneQuarterScreenHeight = MediaQuery.of(context).size.height / 4;

      return PullToSyncWidget(
        child: ListView(
          children: [
            SizedBox(height: oneQuarterScreenHeight),
            Center(child: Text('🎉 Nothing to do.', style: heroFont)),
            Center(child: Text('Click the plus button below to add a ToDo.')),
          ],
        ),
      );
    }

    return PullToSyncWidget(
      child: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return _buildSlidableTaskRow(
            context,
            service,
            tasks[index],
            index,
          );
        },
      ),
    );
  }

  Widget _getSortButton(TaskListService taskListService) {
    return IconButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            return SimpleDialog(
              title: Text('Sort tasks by'),
              children: [
                _getSortOption(taskListService, SortOption.Title),
                _getSortOption(taskListService, SortOption.Flag),
                _getSortOption(taskListService, SortOption.Status),
                _getSortOption(taskListService, SortOption.DueDate),
                _getSortOption(taskListService, SortOption.Created),
              ],
            );
          },
        );
      },
      icon: Icon(Icons.swap_vert),
    );
  }

  SimpleDialogOption _getSortOption(
    TaskListService taskListService,
    SortOption sortOption,
  ) {
    return SimpleDialogOption(
      onPressed: () {
        setState(() {
          taskListService.upsertTaskList(
            widget.taskList..sortBy = sortOption,
            ignoreTasks: true,
          );
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
            service.upsertTask(widget.taskList.id!, task);
          },
        ),
        IconSlideAction(
          caption: 'Delete',
          color: Colors.red,
          icon: Icons.delete,
          onTap: () => service.removeTask(widget.taskList.id!, task.id!),
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
          service.upsertTask(widget.taskList.id!, task);
        },
      ),
    );
  }

  List<Task> _sortTasks(SortOption sortOption, List<Task> tasks) {
    switch (sortOption) {
      case SortOption.Title:
        return tasks..sort(_titleIdCompare);
      case SortOption.Flag:
        return tasks
          ..sort((a, b) => a.isFlagged != b.isFlagged
              ? (a.isFlagged ? -1 : 1)
              : _titleIdCompare(a, b));
      case SortOption.Status:
        return tasks
          ..sort((a, b) => a.completed != b.completed
              ? (a.completed ? -1 : 1)
              : _titleIdCompare(a, b));
      case SortOption.DueDate:
        return tasks
          ..sort((a, b) {
            if (a.due == null) return b.due == null ? _titleIdCompare(a, b) : 1;
            if (b.due == null) return -1;
            final cmp = a.due!.compareTo(b.due!);
            if (cmp != 0) return cmp;

            return _titleIdCompare(a, b);
          });
      case SortOption.Created:
      default:
        return tasks..sort(_titleIdCompare);
    }
  }

  int _titleIdCompare(Task a, Task b) {
    final cmp = a.title.compareTo(b.title);
    if (cmp != 0) return cmp;
    if (a.id == null) return b.id == null ? 0 : 1;
    if (b.id == null) return -1;

    return a.id!.compareTo(b.id!);
  }
}
