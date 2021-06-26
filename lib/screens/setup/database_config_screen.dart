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
  late final databasePathController =
      TextEditingController(text: widget.directory.path);
  var inMemoryRadioGroupValue = false;

  @override
  Widget build(BuildContext context) {
    return ConfigScreen(
      title: 'Setup Database',
      onSubmit: handleSubmit,
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
                groupValue: inMemoryRadioGroupValue,
                onChanged: (value) => handleInMemoryChanged(value!),
              ),
              Text('Yes'),
              Radio<bool>(
                value: false,
                groupValue: inMemoryRadioGroupValue,
                onChanged: (value) => handleInMemoryChanged(value!),
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
                  color: inMemoryRadioGroupValue
                      ? Theme.of(context).disabledColor
                      : Theme.of(context).textTheme.bodyText1!.color,
                ),
              ),
            ],
          ),
          TextFormField(
            decoration: InputDecoration(
              enabled: !inMemoryRadioGroupValue,
              helperMaxLines: 2,
              helperText:
                  'The task lists and tasks you create, will be stored in a file at this location.',
            ),
            controller: databasePathController,
            onFieldSubmitted: (value) async =>
                await handleDatabasePathSubmitted(value),
          ),
        ],
      ),
    );
  }

  void handleSubmit() async {
    await handleDatabasePathSubmitted(
      databasePathController.text,
    );
    DependenciesProvider.rebuild(context);
  }

  Future<void> handleInMemoryChanged(bool inMemory) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setBool(
      SharedPreferencesKeys.inMemory.value,
      inMemory,
    );
    setState(() {
      inMemoryRadioGroupValue = inMemory;
    });
  }

  Future<void> handleDatabasePathSubmitted(String databasePath) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString(
      SharedPreferencesKeys.databasePath.value,
      databasePath,
    );
  }
}
