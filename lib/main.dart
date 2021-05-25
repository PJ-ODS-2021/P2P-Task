import 'package:flutter/material.dart';
import 'package:p2p_task/network/peer.dart';
import 'package:p2p_task/screens/home_screen.dart';
import 'package:p2p_task/services/network_info_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TaskListService.instance),
        ChangeNotifierProvider(create: (context) => NetworkInfoService(null)),
        ChangeNotifierProvider(create: (context) => Peer.instance),
      ],
      child: MaterialApp(
        title: 'P2P Task Manager',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
        ),
        home: HomeScreen(title: 'P2P Task Manager'),
      ),
    );
  }
}
