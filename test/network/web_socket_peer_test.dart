import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/network/messages/packet.dart';
import 'package:p2p_task/network/messages/task_list_message.dart';
import 'package:p2p_task/network/peer/web_socket_client.dart';
import 'package:p2p_task/network/web_socket_peer.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/peer_info_service.dart';
import 'package:p2p_task/services/peer_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/utils/data_model_repository.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:lww_crdt/lww_crdt.dart';

void main() {
  late Database db;
  late KeyValueRepository keyValueRepository;
  late IdentityService identityService;
  late TaskListService taskListService;
  late SyncService syncService;
  late PeerInfoService peerInfoService;
  late PeerService peerService;

  setUp(() async {
    db = await databaseFactoryMemory.openDatabase('');
    keyValueRepository = KeyValueRepository(db);
    identityService = IdentityService(keyValueRepository);
    syncService = SyncService(keyValueRepository);
    await syncService.setInterval(0);
    taskListService =
        TaskListService(keyValueRepository, identityService, syncService);
    peerInfoService = PeerInfoService(DataModelRepository(
      db,
      (json) => PeerInfo.fromJson(json),
      'PeerInfo',
    ));
    peerService = PeerService(
      WebSocketPeer(),
      taskListService,
      peerInfoService,
      identityService,
      syncService,
    );
    await peerService.startServer();
  });

  group('Synchronization', () {
    test('should sync with connecting client', () async {
      /// This manual task message setup is very implementation sepcific and kind of hard to maintain:
      final task = Task(
        title: 'Eat a hot dog',
        id: '16ca13c-9021-4986-ab97-2d89cc0b3fce',
      );
      final crdt =
          MapCrdt<String, MapCrdtNode<String, dynamic>>('0000_localNode');
      final crdtTaskNode = MapCrdtNode<String, dynamic>(crdt);
      (task.toJson()..remove('id'))
          .forEach((key, value) => crdtTaskNode.put(key, value));
      crdt.put(task.id!, crdtTaskNode);
      final messageContent =
          crdt.toJson(valueEncode: (value) => value.toJson());

      final peerLocation =
          PeerLocation('ws://localhost:${await identityService.port}');
      final client = WebSocketClient.connect(peerLocation.uri);
      var completer = Completer();
      client.dataStream.listen((data) {
        completer.complete(data);
      });
      client.send(jsonEncode(Packet(
        'TaskListMessage',
        object: TaskListMessage(
          jsonEncode(messageContent),
          requestReply: true,
        ).toJson(),
      )));
      final serverData = await completer.future
          .timeout(Duration(seconds: 5), onTimeout: () => null);
      expect(
        serverData,
        isNot(equals(null)),
        reason: 'server did not answer within 5s',
      );

      final unmarshalledData = TaskListMessage.fromJson(
        Packet.fromJson(jsonDecode(serverData)).object,
      ).taskListCrdtJson;

      // simulate the changes that should have happened and how the received message should look like
      final remotePeerId = await identityService.peerId;
      crdt.addNode(remotePeerId);
      final expectedMessageContent =
          crdt.toJson(valueEncode: (value) => value.toJson())
            ..['node'] = remotePeerId
            ..['vectorClock'].last += 1;

      expect(jsonDecode(unmarshalledData), expectedMessageContent);
      final tasks = await taskListService.tasks;
      expect(tasks.length, equals(1));
      expect(tasks.first, task);
    });
  });

  tearDown(() async {
    await peerService.stopServer();
    await db.close();
  });
}
