import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final quarterPadding = screenWidth * 0.25 / 2;

    return Scaffold(
      body: Container(
        margin: const EdgeInsets.all(16.0),
        padding:
            EdgeInsets.symmetric(vertical: 32.0, horizontal: quarterPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Setup Database',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Spacer(
              flex: 4,
            ),
            Text('Use in memory database?'),
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
            Text(
              'Choose database location:',
              style: TextStyle(
                color: inMemoryRadioGroupValue
                    ? Theme.of(context).disabledColor
                    : Theme.of(context).textTheme.bodyText1!.color,
              ),
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
            SizedBox(
              height: 16,
            ),
            Spacer(
              flex: 1,
            ),
            Center(
              child: MaterialButton(
                padding: const EdgeInsets.all(16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                onPressed: () async {
                  await handleDatabasePathSubmitted(
                    databasePathController.text,
                  );
                  DependenciesProvider.rebuild(context);
                },
                color: Theme.of(context).accentColor,
                textColor: Colors.white,
                child: Text('OK'),
              ),
            ),
            Spacer(
              flex: 2,
            ),
          ],
        ),
      ),
    );
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
