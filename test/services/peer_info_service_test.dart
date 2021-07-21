import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/services/peer_info_service.dart';
import 'package:p2p_task/utils/data_model_repository.dart';
import 'package:p2p_task/utils/store_ref_names.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  group('#PeerInfoService', () {
    late Database database;
    late PeerInfoService peerInfoService;

    setUp(() async {
      database = await (newDatabaseFactoryMemory())
          .openDatabase(sembastInMemoryDatabasePath);
      final dataModelRepository = DataModelRepository(
        database,
        (json) => PeerInfo.fromJson(json),
        StoreRefNames.peerInfo.value,
      );
      peerInfoService = PeerInfoService(dataModelRepository, null);
    });

    test('upsert', () async {
      expect(await peerInfoService.devices, []);
      final peerInfo = PeerInfo(
        name: 'peerName',
        status: Status.active,
        publicKeyPem: '',
        locations: [],
      );
      await peerInfoService.upsert(peerInfo);
      expect(await peerInfoService.devices, [peerInfo]);
    });

    test('getById', () async {
      expect(await peerInfoService.getById('peerId'), null);
      final peerInfo = PeerInfo(
        id: 'peerId',
        name: 'peerName',
        status: Status.active,
        publicKeyPem: '',
        locations: [],
      );
      await peerInfoService.upsert(peerInfo);
      expect(await peerInfoService.getById('peerId'), peerInfo);
    });

    test('remove', () async {
      final peerInfo = PeerInfo(
        name: 'peerName',
        status: Status.active,
        publicKeyPem: '',
        locations: [],
      );
      await peerInfoService.upsert(peerInfo);
      await peerInfoService.remove(peerInfo.id);
      expect(await peerInfoService.devices, []);
    });

    test('update existent', () async {
      final peerInfo = PeerInfo(
        name: 'peerName',
        status: Status.active,
        publicKeyPem: '',
        locations: [],
      );
      await peerInfoService.upsert(peerInfo);
      await peerInfoService.update(
        peerInfo.id,
        (peerInfo) => peerInfo?..status = Status.created,
      );
      expect(
        await peerInfoService.devices,
        [peerInfo..status = Status.created],
      );
    });

    test('update remove', () async {
      final peerInfo = PeerInfo(
        name: 'peerName',
        status: Status.active,
        publicKeyPem: '',
        locations: [],
      );
      await peerInfoService.upsert(peerInfo);
      await peerInfoService.update(peerInfo.id, (peerInfo) => null);
      expect(await peerInfoService.devices, []);
    });

    test('update add', () async {
      final peerInfo = PeerInfo(
        id: 'peerId',
        name: 'peerName',
        status: Status.active,
        publicKeyPem: '',
        locations: [],
      );
      await peerInfoService.update(peerInfo.id, (_) => peerInfo);
      expect(await peerInfoService.devices, [peerInfo]);
    });

    test('update id to null', () async {
      final peerInfo = PeerInfo(
        id: 'peerId',
        name: 'peerName',
        status: Status.active,
        publicKeyPem: '',
        locations: [],
      );
      await peerInfoService.upsert(peerInfo);
      await peerInfoService.update(
        peerInfo.id,
        (peerInfo) => peerInfo
          ?..id = null
          ..name = 'newPeerName',
      );
      expect(await peerInfoService.devices, [peerInfo..name = 'newPeerName']);
    });

    test('update change id', () async {
      final peerInfo = PeerInfo(
        id: 'peerId',
        name: 'peerName',
        status: Status.active,
        publicKeyPem: '',
        locations: [],
      );
      await peerInfoService.upsert(peerInfo);
      await peerInfoService.update(
        peerInfo.id,
        (peerInfo) => peerInfo?..id = 'newPeerId',
      );
      expect(await peerInfoService.devices, [peerInfo..id = 'newPeerId']);
    });

    test('update null id', () async {
      final peerInfo = PeerInfo(
        name: 'peerName',
        status: Status.active,
        publicKeyPem: '',
        locations: [],
      );
      await peerInfoService.update(null, (_) => peerInfo);
      expect(await peerInfoService.devices, [peerInfo]);
    });

    test('update null id to null', () async {
      await peerInfoService.update(null, (_) => null);
      expect(await peerInfoService.devices, []);
    });

    test('activeDevices', () async {
      final peerInfos = [
        PeerInfo(
          name: 'peer1',
          status: Status.active,
          publicKeyPem: '',
          locations: [],
        ),
        PeerInfo(
          name: 'peer2',
          status: Status.created,
          publicKeyPem: '',
          locations: [],
        ),
      ];
      await Future.wait(peerInfos.map(peerInfoService.upsert));
      expect(await peerInfoService.activeDevices, [peerInfos[0]]);
    });

    test('deviceNameMap', () async {
      final peerInfos = [
        PeerInfo(
          id: 'peerId1',
          name: 'peer1',
          status: Status.active,
          publicKeyPem: '',
          locations: [],
        ),
        PeerInfo(
          id: 'peerId2',
          name: 'peer2',
          status: Status.created,
          publicKeyPem: '',
          locations: [],
        ),
      ];
      await Future.wait(peerInfos.map(peerInfoService.upsert));
      expect(
        await peerInfoService.deviceNameMap,
        {'peerId1': 'peer1', 'peerId2': 'peer2'},
      );
    });

    tearDown(() async {
      await database.close();
    });
  });
}
