import 'package:flutter/material.dart';
import 'package:p2p_task/screens/home_screen.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'P2P Task Manager',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.deepPurple,
      ),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => TaskListService()),
        ],
        child: HomeScreen(title: 'P2P Task Manager'),
      ),
    );
  }
}
