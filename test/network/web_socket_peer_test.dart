import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/network/messages/task_list_message.dart';
import 'package:p2p_task/network/messages/packet.dart';
import 'package:p2p_task/network/peer/web_socket_client.dart';
import 'package:p2p_task/network/peer/web_socket_server.dart';
import 'package:p2p_task/network/web_socket_peer.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/peer_info_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/utils/data_model_repository.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  late Database db;
  late KeyValueRepository keyValueRepository;
  late IdentityService identityService;
  late TaskListService taskListService;
  late PeerInfoService deviceService;
  late SyncService syncService;
  late WebSocketPeer peer;

  setUp(() async {
    db = await databaseFactoryMemory.openDatabase('');
    keyValueRepository = KeyValueRepository(db);
    identityService = IdentityService(keyValueRepository);
    syncService = SyncService(keyValueRepository);
    await syncService.setInterval(0);
    taskListService =
        TaskListService(keyValueRepository, identityService, syncService);
    deviceService = PeerInfoService(
        DataModelRepository(db, (json) => PeerInfo.fromJson(json), 'PeerInfo'));
    peer = WebSocketPeer(WebSocketServer.instance, WebSocketClient.instance,
        taskListService, deviceService, identityService, syncService);
  });

  group('Synchronization', () {
    test('should sync with connecting client', () async {
      final taskTitle = 'Eat a hot dog';
      final message =
          '{"516ca13c-9021-4986-ab97-2d89cc0b3fce":{"hlc":"2021-06-04T07:37:08.946Z-0000-d5726a08-2107-49c0-8b06-167e57f96301","value":{"id":"516ca13c-9021-4986-ab97-2d89cc0b3fce","title":"$taskTitle","completed":false,"due":null,"dueNotification":null,"priority":null}}}';

      final port = await identityService.port;
      WebSocketClient.instance.connect('localhost', port);
      var completer = Completer();
      WebSocketClient.instance.dataStream.listen((data) {
        completer.complete(data);
      });
      WebSocketClient.instance.send(jsonEncode(Packet('TaskListMessage',
          object: TaskListMessage(message, requestReply: true).toJson())));
      final serverData = await completer.future;

      final unmarshalledData = TaskListMessage.fromJson(
              Packet.fromJson(jsonDecode(serverData)).object)
          .taskListCrdtJson;
      expect(unmarshalledData, message);
      final tasks = await taskListService.tasks;
      expect(tasks.length, equals(1));
      expect(tasks.first.title, equals(taskTitle));
    });
  });

  tearDown(() async {
    await peer.stopServer();
    await db.close();
  });
}
