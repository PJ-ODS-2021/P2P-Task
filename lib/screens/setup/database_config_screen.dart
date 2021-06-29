import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:p2p_task/screens/setup/config_screen.dart';
import 'package:p2p_task/screens/setup/dependencies_provider.dart';
import 'package:p2p_task/utils/shared_preferences_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseConfigScreen extends StatefulWidget {
  final Directory directory;

  DatabaseConfigScreen(this.directory);

  @override
  State<StatefulWidget> createState() => _DatabaseConfigScreenState();
}

class _DatabaseConfigScreenState extends State<DatabaseConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _databasePathController = TextEditingController();
  var _inMemoryRadioGroupValue = false;

  @override
  Widget build(BuildContext context) {
    return ConfigScreen(
      title: 'Setup Database',
      onSubmit: _handleSubmit,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                Text('Use in memory database?'),
              ],
            ),
            SizedBox(
              height: 8,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: _inMemoryRadioGroupValue,
                  onChanged: (value) => _handleInMemoryChanged(value!),
                ),
                Text('Yes'),
                Radio<bool>(
                  value: false,
                  groupValue: _inMemoryRadioGroupValue,
                  onChanged: (value) => _handleInMemoryChanged(value!),
                ),
                Text('No'),
              ],
            ),
            SizedBox(
              height: 22,
            ),
            Row(
              children: [
                Text(
                  'Choose database location:',
                  style: TextStyle(
                    color: _inMemoryRadioGroupValue
                        ? Theme.of(context).disabledColor
                        : Theme.of(context).textTheme.bodyText1!.color,
                  ),
                ),
              ],
            ),
            TextFormField(
              validator: _validateDatabasePath,
              decoration: InputDecoration(
                enabled: !_inMemoryRadioGroupValue,
                helperMaxLines: 2,
                helperText:
                    'The task lists and tasks you create, will be stored in a file at this location.',
              ),
              controller: _inMemoryRadioGroupValue
                  ? (_databasePathController..text = '')
                  : (_databasePathController..text = widget.directory.path),
              onFieldSubmitted: (value) async =>
                  await _handleDatabasePathSubmitted(value),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateDatabasePath(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please specify a path.';
    }

    return null;
  }

  void _handleSubmit() async {
    await _handleDatabasePathSubmitted(
      _databasePathController.text,
    );
    DependenciesProvider.rebuild(context);
  }

  Future<void> _handleInMemoryChanged(bool inMemory) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setBool(
      SharedPreferencesKeys.inMemory.value,
      inMemory,
    );
    setState(() {
      _inMemoryRadioGroupValue = inMemory;
    });
  }

  Future<void> _handleDatabasePathSubmitted(String databasePath) async {
    if (!_formKey.currentState!.validate()) return;
    final sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString(
      SharedPreferencesKeys.databasePath.value,
      databasePath,
    );
  }
}
