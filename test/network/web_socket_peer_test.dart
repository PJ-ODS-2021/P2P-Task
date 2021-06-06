import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/network/messages/task_list_message.dart';
import 'package:p2p_task/network/messages/packet.dart';
import 'package:p2p_task/network/peer/web_socket_client.dart';
import 'package:p2p_task/network/web_socket_peer.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  late Database db;
  late KeyValueRepository keyValueRepository;
  late IdentityService identityService;
  late TaskListService taskListService;
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
    peer = WebSocketPeer();
    peer.startServer(await identityService.port);
  });

  group('Synchronization', () {
    test('should sync with connecting client', () async {
      final taskTitle = 'Eat a hot dog';
      final message =
          '{"516ca13c-9021-4986-ab97-2d89cc0b3fce":{"hlc":"2021-06-04T07:37:08.946Z-0000-d5726a08-2107-49c0-8b06-167e57f96301","value":{"id":"516ca13c-9021-4986-ab97-2d89cc0b3fce","title":"$taskTitle","completed":false,"due":null,"dueNotification":null,"priority":null}}}';

      final peerInfo = PeerInfo()
        ..ip = 'localhost'
        ..port = await identityService.port;
      final client = WebSocketClient.connect(peerInfo.websocketUri);
      var completer = Completer();
      client.dataStream.listen((data) {
        completer.complete(data);
      });
      client.send(jsonEncode(Packet('TaskListMessage',
          object: TaskListMessage(message, requestReply: true).toJson())));
      final serverData = await completer.future
          .timeout(Duration(seconds: 5), onTimeout: () => null);
      expect(serverData, isNot(equals(null)),
          reason: 'server did not answer within 5s');

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
