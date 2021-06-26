import 'package:flutter/material.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:p2p_task/config/app_module.dart';
import 'package:p2p_task/config/style_constants.dart';
import 'package:p2p_task/screens/initial_setup_screen.dart';
import 'package:p2p_task/services/activity_entry_service.dart';
import 'package:p2p_task/services/device_info_service.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/network_info_service.dart';
import 'package:p2p_task/services/peer_info_service.dart';
import 'package:p2p_task/services/peer_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/services/task_lists_service.dart';
import 'package:p2p_task/widgets/app_lifecycle_reactor.dart';
import 'package:provider/provider.dart';
import 'package:sembast/sembast.dart';

void main() async {
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildAwaitAppModule(
      context,
      MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'P2P Task Manager',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          canvasColor: kGrayBackground,
        ),
        home: InitialSetupDialog(),
      ),
    );
  }

  Widget _buildAwaitAppModule(BuildContext context, Widget child) {
    return FutureBuilder<Injector>(
      future: AppModule().initialize(Injector()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton(context, CircularProgressIndicator());
        }
        if (snapshot.hasError) {
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
        }
        final injector = snapshot.data!;

        return _buildProviders(context, injector, child);
      },
    );
  }

  Widget _buildProviders(
    BuildContext context,
    Injector injector,
    Widget child,
  ) {
    return MultiProvider(
      providers: [
        Provider(create: (context) => injector.get<DeviceInfoService>()),
        Provider(create: (context) => injector.get<Database>()),
        ChangeNotifierProvider(create: (context) => ActivityEntryService()),
        ChangeNotifierProvider(
          create: (context) => ChangeCallbackNotifier<TaskListService>(
            injector.get<TaskListService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ChangeCallbackNotifier<TaskListsService>(
            injector.get<TaskListsService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ChangeCallbackNotifier<NetworkInfoService>(
            injector.get<NetworkInfoService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ChangeCallbackNotifier<PeerInfoService>(
            injector.get<PeerInfoService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ChangeCallbackNotifier<IdentityService>(
            injector.get<IdentityService>(),
          ),
        ),
        ChangeNotifierProvider.value(
          value: ChangeCallbackNotifier<PeerService>(
            injector.get<PeerService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ChangeCallbackNotifier<SyncService>(
            injector.get<SyncService>(),
          ),
        ),
      ],
      child: AppLifecycleReactor(
        onResume: () async =>
            await injector.get<SyncService>().run(runOnSyncOnStart: true),
        child: child,
      ),
    );
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
