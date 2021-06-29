import 'package:flutter/material.dart';
import 'package:p2p_task/models/task_list.dart';
import 'package:p2p_task/services/task_lists_service.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:provider/provider.dart';

class TaskListFormScreen extends StatefulWidget {
  final TaskList? taskList;

  TaskListFormScreen({Key? key, this.taskList}) : super(key: key);

  @override
  _TaskListFormScreenState createState() => _TaskListFormScreenState();
}

class _TaskListFormScreenState extends State<TaskListFormScreen> {
  late final _taskList;
  final _formKey = GlobalKey<FormState>();
  late final _formTitleController =
      TextEditingController(text: _taskList.title);

  bool _editing = false;

  void _onSubmitPressed(context) {
    if (_formKey.currentState!.validate()) {
      final listService = Provider.of<ChangeCallbackNotifier<TaskListsService>>(
        context,
        listen: false,
      ).callbackProvider;
      listService.upsert(_taskList..title = _formTitleController.text);
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.taskList != null) {
      _taskList = widget.taskList;
      _editing = true;
    } else {
      _taskList = TaskList(title: '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add List'), centerTitle: true),
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
                    return 'Give your list a title.';
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
            ),
            Spacer(flex: 5),
            ElevatedButton(
              onPressed: () => _onSubmitPressed(context),
              child: Text(_editing ? 'Update List' : 'Create List'),
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
    super.dispose();
  }
}
