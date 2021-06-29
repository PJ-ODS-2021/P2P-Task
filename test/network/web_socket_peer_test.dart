import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/models/task.dart';
import 'package:p2p_task/models/task_list.dart';
import 'package:p2p_task/network/messages/introduction_message.dart';
import 'package:p2p_task/network/messages/packet.dart';
import 'package:p2p_task/network/messages/task_list_message.dart';
import 'package:p2p_task/network/messages/task_lists_message.dart';
import 'package:p2p_task/network/peer/web_socket_client.dart';
import 'package:p2p_task/network/web_socket_peer.dart';
import 'package:p2p_task/security/key_helper.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/peer_info_service.dart';
import 'package:p2p_task/services/peer_service.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/services/task_list_service.dart';
import 'package:p2p_task/services/task_lists_service.dart';
import 'package:p2p_task/utils/data_model_repository.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:pointycastle/export.dart';

void main() {
  late Database db;
  late KeyValueRepository keyValueRepository;
  late IdentityService identityService;
  late TaskListService taskListService;
  late TaskListsService taskListsService;
  late SyncService syncService;
  late PeerInfoService peerInfoService;
  late PeerService peerService;
  late AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> keys;

  var keyHelper = KeyHelper();

  setUp(() async {
    db = await databaseFactoryMemory.openDatabase('');
    keyValueRepository = KeyValueRepository(db);
    identityService = IdentityService(keyValueRepository);

    keys = keyHelper.generateRSAkeyPair();
    await identityService
        .setPrivateKeyPem(keyHelper.encodePrivateKeyToPem(keys.privateKey));
    await identityService
        .setPublicKeyPem(keyHelper.encodePublicKeyToPem(keys.publicKey));

    syncService = SyncService(keyValueRepository);
    await syncService.setInterval(0);
    taskListService =
        TaskListService(keyValueRepository, identityService, syncService);
    taskListsService =
        TaskListsService(keyValueRepository, identityService, syncService);
    peerInfoService = PeerInfoService(
      DataModelRepository(
        db,
        (json) => PeerInfo.fromJson(json),
        'PeerInfo',
      ),
      syncService,
    );
    peerService = PeerService(
      WebSocketPeer(),
      taskListService,
      taskListsService,
      peerInfoService,
      identityService,
      syncService,
    );
    await peerService.startServer();
  });

  group('Synchronization', () {
    test('should sync tasks with connecting client', () async {
      final task = Task(
        title: 'Eat a hot dog',
        id: '16ca13c-9021-4986-ab97-2d89cc0b3fce',
        taskListID: '1',
      );
      final message = <String, dynamic>{
        '516ca13c-9021-4986-ab97-2d89cc0b3fce': {
          'hlc':
              '2021-06-04T07:37:08.946Z-0000-d5726a08-2107-49c0-8b06-167e57f96301',
          'value': task.toJson(),
        },
      };

      final peerLocation =
          PeerLocation('ws://localhost:${await identityService.port}');
      final client = WebSocketClient.connect(peerLocation.uri);
      var completer = Completer();
      client.dataStream.listen((data) {
        var dataConv = keyHelper.decrypt(keys.privateKey, data as String);
        completer.complete(dataConv);
      });

      final payload = jsonEncode(
        Packet(
          'TaskListMessage',
          object: TaskListMessage(
            jsonEncode(message),
            keyHelper.encodePublicKeyToPem(keys.publicKey),
            requestReply: true,
          ).toJson(),
        ),
      );

      var encryptedPayload = keyHelper.encrypt(
        keys.publicKey,
        payload,
      );

      client.send(encryptedPayload);
      final serverData =
          await completer.future.timeout(Duration(seconds: 5), onTimeout: () {
        return null;
      });
      expect(
        serverData,
        isNot(equals(null)),
        reason: 'server did not answer within 5s',
      );

      final unmarshalledData = TaskListMessage.fromJson(
        Packet.fromJson(jsonDecode(serverData)).object,
      ).taskListCrdtJson;
      expect(jsonDecode(unmarshalledData), message);
      final tasks = await taskListService.tasks;
      expect(tasks.length, equals(1));
      expect(tasks.first, task);
    });

    test('should sync lists with connecting client', () async {
      final list = TaskList(
        title: 'Fun things to do',
        id: '16ca13c-9021-4986-ab97-2d89cc0b3fce',
      );
      final message = <String, dynamic>{
        '516ca13c-9021-4986-ab97-2d89cc0b3fce': {
          'hlc':
              '2021-06-04T07:37:08.946Z-0000-d5726a08-2107-49c0-8b06-167e57f96301',
          'value': list.toJson(),
        },
      };

      final peerLocation =
          PeerLocation('ws://localhost:${await identityService.port}');
      final client = WebSocketClient.connect(peerLocation.uri);
      var completer = Completer();
      client.dataStream.listen((data) {
        var dataConv = keyHelper.decrypt(keys.privateKey, data as String);
        completer.complete(dataConv);
      });

      final payload = jsonEncode(Packet(
        'TaskListsMessage',
        object: TaskListsMessage(
          jsonEncode(message),
          keyHelper.encodePublicKeyToPem(keys.publicKey),
          requestReply: true,
        ).toJson(),
      ));

      var encryptedPayload = keyHelper.encrypt(
        keys.publicKey,
        payload,
      );

      client.send(encryptedPayload);
      final serverData = await completer.future
          .timeout(Duration(seconds: 5), onTimeout: () => null);
      expect(
        serverData,
        isNot(equals(null)),
        reason: 'server did not answer within 5s',
      );

      final lists = await taskListsService.lists;

      expect(lists.length, equals(2));
      expect(lists[0], list);
      list.isShared = true;
      expect(lists[1], list);
    });

    test('should send introduction message', () async {
      final peerLocation =
          PeerLocation('ws://localhost:${await identityService.port}');
      final client = WebSocketClient.connect(peerLocation.uri);
      var completer = Completer();
      client.dataStream.listen((data) {
        var dataConv = keyHelper.decrypt(keys.privateKey, data as String);
        completer.complete(dataConv);
      });

      var introMessage =
          'Hallo from Clementine here are my informations: 123455,Clementine ,iPhone,0.0.0.0,12345,${keyHelper.encodePublicKeyToPem(keys.publicKey)}';

      final message = jsonEncode(Packet(
        'IntroductionMessage',
        object: IntroductionMessage(
          jsonEncode(introMessage),
          requestReply: true,
        ).toJson(),
      ));

      var payload = keyHelper.encrypt(
        keys.publicKey,
        message,
      );

      client.send(payload);
      final serverData =
          await completer.future.timeout(Duration(seconds: 5), onTimeout: () {
        return null;
      }) as String;
      expect(
        serverData,
        isNot(equals(null)),
        reason: 'server did not answer within 5s',
      );

      expect(true, serverData.contains('Hello back from'));
    });
  });

  tearDown(() async {
    await peerService.stopServer();
    await db.close();
  });
}
