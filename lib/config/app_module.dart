import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:p2p_task/services/database_service.dart';
import 'package:p2p_task/config/migrations.dart';
import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/network/web_socket_peer.dart';
import 'package:p2p_task/services/device_info_service.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/network_info_service.dart';
import 'package:p2p_task/services/peer_info_service.dart';
import 'package:p2p_task/services/peer_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/services/task_lists_service.dart';
import 'package:p2p_task/utils/data_model_repository.dart';
import 'package:p2p_task/utils/shared_preferences_keys.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:p2p_task/utils/store_ref_names.dart';
import 'package:sembast/sembast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppModule {
  Future<void> initialize(Injector injector) async {
    injector.dispose();
    injector = Injector();

    final sharedPreferences = await SharedPreferences.getInstance();
    injector.map((injector) => sharedPreferences, isSingleton: true);
    final inMemory =
        sharedPreferences.containsKey(SharedPreferencesKeys.inMemory.value)
            ? sharedPreferences.getBool(SharedPreferencesKeys.inMemory.value)!
            : false;
    injector.map<DatabaseService>(
      (i) => DatabaseService(1, 'p2p_task', inMemory, migrations),
      isSingleton: true,
    );
    if (sharedPreferences
        .containsKey(SharedPreferencesKeys.databasePath.value)) {
      final databasePath =
          sharedPreferences.getString(SharedPreferencesKeys.databasePath.value);
      await injector.get<DatabaseService>().create(
            dbPath: databasePath,
          );
    } else {
      await injector.get<DatabaseService>().create();
    }
    injector.map<Database>(
      (i) => i.get<DatabaseService>().database!,
      isSingleton: true,
    );
    injector.map<KeyValueRepository>(
      (i) => KeyValueRepository(
        i.get<Database>(),
        StoreRef(StoreRefNames.settings.value),
      ),
      isSingleton: true,
      key: StoreRefNames.settings.value,
    );
    injector.map<KeyValueRepository>(
      (i) => KeyValueRepository(
        i.get<Database>(),
        StoreRef(StoreRefNames.tasks.value),
      ),
      isSingleton: true,
      key: StoreRefNames.tasks.value,
    );
    injector.map<WebSocketPeer>(
      (i) => WebSocketPeer(),
      isSingleton: true,
    );
    injector.map<IdentityService>(
      (i) => IdentityService(
        injector.get<KeyValueRepository>(key: StoreRefNames.settings.value),
      ),
      isSingleton: true,
    );
    injector.map<DeviceInfoService>(
      (i) => DeviceInfoService(),
      isSingleton: true,
    );
    injector.map<NetworkInfoService>(
      (i) => NetworkInfoService(),
      isSingleton: true,
    );
    injector.map<PeerInfoService>(
      (i) => PeerInfoService(DataModelRepository(
        i.get<Database>(),
        (json) => PeerInfo.fromJson(json),
        StoreRefNames.peerInfo.value,
      )),
      isSingleton: true,
    );
    injector.map<PeerService>(
      (i) => PeerService(
        i.get<WebSocketPeer>(),
        i.get<TaskListService>(),
        i.get<TaskListsService>(),
        i.get<PeerInfoService>(),
        i.get<IdentityService>(),
        i.get<SyncService>(),
      ),
      isSingleton: true,
    );
    injector.map<SyncService>(
      (i) => SyncService(
        i.get<KeyValueRepository>(key: StoreRefNames.settings.value),
      ),
      isSingleton: true,
    );
    injector.map<TaskListService>(
      (i) => TaskListService(
        i.get<KeyValueRepository>(key: StoreRefNames.tasks.value),
        i.get<IdentityService>(),
        i.get<SyncService>(),
      ),
      isSingleton: true,
    );
    injector.map<TaskListsService>(
      (i) => TaskListsService(
        i.get<KeyValueRepository>(key: StoreRefNames.tasks.value),
        i.get<IdentityService>(),
        i.get<SyncService>(),
      ),
      isSingleton: true,
    );
  }
}
