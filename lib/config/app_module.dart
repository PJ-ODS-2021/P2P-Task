import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:p2p_task/config/database_creator.dart';
import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/network/peer.dart';
import 'package:p2p_task/network/peer/web_socket_client.dart';
import 'package:p2p_task/network/peer/web_socket_server.dart';
import 'package:p2p_task/network/web_socket_peer.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/network_info_service.dart';
import 'package:p2p_task/services/peer_info_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/utils/data_model_repository.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:sembast/sembast.dart';

class AppModule {
  static bool _initialized = false;
  late Database _db;

  Future<Injector> initialize(Injector injector) async {
    if (_initialized) return injector;
    _db = await DatabaseCreator.create();

    injector.map<Database>((i) => _db);
    injector.map<NetworkInfoService>((i) => NetworkInfoService());
    injector.map<KeyValueRepository>((i) => KeyValueRepository(_db),
        isSingleton: true);
    injector.map<SyncService>((i) => SyncService(i.get<KeyValueRepository>()),
        isSingleton: true);
    injector.map<IdentityService>(
        (i) => IdentityService(i.get<KeyValueRepository>()));
    injector.map<TaskListService>((i) => TaskListService(
        i.get<KeyValueRepository>(),
        i.get<IdentityService>(),
        i.get<SyncService>()));
    injector.map<PeerInfoService>((i) => PeerInfoService(DataModelRepository(
        _db, (json) => PeerInfo.fromJson(json), 'PeerInfo')));
    injector.map<Peer>((i) => Peer.instance());
    injector.map<WebSocketServer>((i) => WebSocketServer.instance);
    injector.map<WebSocketPeer>(
        (i) => WebSocketPeer(
            i.get<WebSocketServer>(),
            WebSocketClient.instance,
            i.get<TaskListService>(),
            i.get<PeerInfoService>(),
            i.get<IdentityService>(),
            i.get<SyncService>()),
        isSingleton: true);

    _initialized = true;
    return injector;
  }
}
