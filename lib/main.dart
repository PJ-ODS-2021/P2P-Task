import 'package:flutter/material.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:p2p_task/config/app_module.dart';
import 'package:p2p_task/config/style_constants.dart';
import 'package:p2p_task/screens/home_screen.dart';
import 'package:p2p_task/services/activity_entry_service.dart';
import 'package:p2p_task/services/device_info_service.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/network_info_service.dart';
import 'package:p2p_task/services/peer_info_service.dart';
import 'package:p2p_task/services/peer_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:provider/provider.dart';
import 'package:sembast/sembast.dart';

void main() async {
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildProviders(
      context,
      MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'P2P Task Manager',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          canvasColor: kGrayBackground,
        ),
        home: HomeScreen(title: 'P2P Task Manager'),
      ),
    );
  }

  Widget _buildProviders(BuildContext context, Widget child) {
    return FutureBuilder<Injector>(
        future: AppModule().initialize(Injector()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return _buildSkeleton(context, CircularProgressIndicator());
          if (snapshot.hasError)
            return _buildSkeleton(
              context,
              Column(
                children: [
                  Text('Error'),
                  Text(snapshot.error.toString()),
                  Text(snapshot.stackTrace.toString()),
                ],
              ),
            );
          final i = snapshot.data!;
          return MultiProvider(providers: [
            Provider(
              create: (context) => DeviceInfoService(null),
            ),
            Provider(create: (context) => i.get<Database>()),
            ChangeNotifierProvider(
                create: (context) => i.get<TaskListService>()),
            ChangeNotifierProvider(
                create: (context) => i.get<NetworkInfoService>()),
            ChangeNotifierProvider(
                create: (context) => i.get<PeerInfoService>()),
            ChangeNotifierProvider(
                create: (context) => i.get<IdentityService>()),
            ChangeNotifierProvider(create: (context) => i.get<SyncService>()),
            ChangeNotifierProvider.value(value: i.get<PeerService>()),
          ], child: child);
        });
  }

  Widget _buildSkeleton(BuildContext context, Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: child,
        ),
      ),
    );
  }
}
