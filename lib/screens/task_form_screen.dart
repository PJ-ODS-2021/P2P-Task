import 'package:flutter/material.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:provider/provider.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({Key? key, this.task}) : super(key: key);

  @override
  _TaskFormScreenState createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  late final Task _task;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final _formTitleController = TextEditingController(text: _task.title);
  late final _formDescriptionController =
      TextEditingController(text: _task.description);
  bool _editing = false;

  void _onSubmitPressed(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final taskListService =
          Provider.of<TaskListService>(context, listen: false);
      taskListService.upsert(_task
        ..title = _formTitleController.text
        ..description = _formDescriptionController.text);
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _task = widget.task!;
      _editing = true;
    } else {
      _task = Task(title: '');
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

  @override
  void dispose() {
    _formTitleController.dispose();
    _formDescriptionController.dispose();
    super.dispose();
  }
}
