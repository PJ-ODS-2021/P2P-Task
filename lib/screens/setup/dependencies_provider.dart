import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:p2p_task/services/activity_entry_service.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/database_service.dart';
import 'package:p2p_task/services/device_info_service.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/network_info_service.dart';
import 'package:p2p_task/services/peer_info_service.dart';
import 'package:p2p_task/services/peer_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/viewmodels/device_list_viewmodel.dart';
import 'package:p2p_task/widgets/app_lifecycle_reactor.dart';
import 'package:provider/provider.dart';
import 'package:sembast/sembast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DependenciesProvider extends StatefulWidget {
  final Widget child;

  static void rebuild(BuildContext context) {
    context.findAncestorStateOfType<_DependenciesProviderState>()!.rebuild();
  }

  DependenciesProvider({required this.child});

  @override
  _DependenciesProviderState createState() => _DependenciesProviderState();
}

class _DependenciesProviderState extends State<DependenciesProvider> {
  Key key = UniqueKey();

  void rebuild() {
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: key,
      child: _buildProviders(
        context,
        widget.child,
      ),
    );
  }

  Widget _buildProviders(BuildContext context, Widget child) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => Injector().get<DeviceInfoService>()),
        Provider(create: (_) => Injector().get<Database>()),
        Provider(
          create: (_) => Injector().get<SharedPreferences>(),
        ),
        Provider(
          create: (_) => Injector().get<DatabaseService>(),
        ),
        Provider<DeviceListViewModel>(
          create: (_) => DeviceListViewModel(
            Injector().get<PeerInfoService>(),
            Injector().get<PeerService>(),
          ),
          dispose: (_, viewModel) => viewModel.dispose(),
        ),
        ChangeNotifierProvider(create: (_) => ActivityEntryService()),
        ChangeNotifierProvider(
          create: (_) => ChangeCallbackNotifier<TaskListService>(
            Injector().get<TaskListService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ChangeCallbackNotifier<NetworkInfoService>(
            Injector().get<NetworkInfoService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ChangeCallbackNotifier<PeerInfoService>(
            Injector().get<PeerInfoService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ChangeCallbackNotifier<IdentityService>(
            Injector().get<IdentityService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ChangeCallbackNotifier<PeerService>(
            Injector().get<PeerService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ChangeCallbackNotifier<SyncService>(
            Injector().get<SyncService>(),
          ),
        ),
      ],
      child: AppLifecycleReactor(
        onResume: () async =>
            await Injector().get<SyncService>().run(runOnSyncOnStart: true),
        child: child,
      ),
    );
  }
}
