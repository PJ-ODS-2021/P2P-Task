import 'package:flutter/material.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;
  final String taskListID;

  const TaskFormScreen({Key? key, this.task, required this.taskListID})
      : super(key: key);

  @override
  _TaskFormScreenState createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  late final _task;
  DateTime? _due;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final _formTitleController = TextEditingController(text: _task.title);
  late final _formDescriptionController =
      TextEditingController(text: _task.description);
  bool _editing = false;

  void _onSubmitPressed(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final taskListService =
          Provider.of<ChangeCallbackNotifier<TaskListService>>(
        context,
        listen: false,
      ).callbackProvider;
      taskListService.upsert(_task
        ..title = _formTitleController.text
        ..description = _formDescriptionController.text
        ..due = _due);
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _task = widget.task;
      _due = widget.task!.due;
      _editing = true;
    } else {
      _task = Task(title: '', taskListID: widget.taskListID);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Task'), centerTitle: true),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 15.0,
              ),
              child: TextFormField(
                autofocus: true,
                onFieldSubmitted: (value) => _onSubmitPressed(context),
                decoration: InputDecoration(
                  hintText: 'Title',
                  filled: true,
                  fillColor: Colors.purple[50],
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                ),
                controller: _formTitleController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Give your task a title.';
                  }

                  return null;
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 15.0,
              ),
              child: Container(
                child: TextFormField(
                  onFieldSubmitted: (value) => _onSubmitPressed(context),
                  decoration: InputDecoration(
                    hintText: 'Description',
                    filled: true,
                    fillColor: Colors.purple[50],
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                  controller: _formDescriptionController,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 15.0,
              ),
              child: Container(
                child: TextButton(
                  style: ButtonStyle(
                    //minimumSize: Size.fromHeight(50),
                    backgroundColor:
                        MaterialStateProperty.all(Colors.purple[50]),
                  ),
                  onPressed: () => pickDateTime(context),
                  child: Text(
                    _due != null
                        ? DateFormat('dd.MM.yyyy hh:mm').format(_due!)
                        : 'Due Date',
                    textAlign: TextAlign.left,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
            ),
            Spacer(flex: 5),
            ElevatedButton(
              onPressed: () => _onSubmitPressed(context),
              child: Text(_editing ? 'Update Task' : 'Create Task'),
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }

  Future pickDateTime(BuildContext context) async {
    final date = await pickDate(context);
    if (date == null) {
      setState(() {
        _due = null;
      });
      return;
    }

    final time = await pickTime(context);
    if (time == null) {
      setState(() {
        _due = DateTime(
          date.year,
          date.month,
          date.day,
          0,
          0,
        );
      });
      return;
    }

    setState(() {
      _due = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future pickDate(BuildContext context) async {
    final initialDate = DateTime.now();
    final newDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: initialDate,
        lastDate: DateTime(initialDate.year + 10));

    if (newDate == null) return;

    return newDate;
  }

  Future pickTime(BuildContext context) async {
    final initialTime = TimeOfDay(hour: 0, minute: 0);
    final newTime = await showTimePicker(
      context: context,
      initialTime: _due != null
          ? TimeOfDay(hour: _due!.hour, minute: _due!.minute)
          : initialTime,
    );

    if (newTime == null) return;

    return newTime;
  }

  @override
  void dispose() {
    _formTitleController.dispose();
    _formDescriptionController.dispose();
    super.dispose();
  }
}
