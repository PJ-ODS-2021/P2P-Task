import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/utils/data_model_repository.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:uuid/uuid.dart';

void main() {
  late Database database;
  late DataModelRepository<PeerInfo> dataModelRepository;

  Future<void> _resetDatabase() async {
    await databaseFactoryMemory.deleteDatabase('');
    database = await databaseFactoryMemory.openDatabase('');
    dataModelRepository = DataModelRepository(
      database,
      (json) => PeerInfo.fromJson(json),
      'PeerInfo',
    );
  }

  setUp(() async {
    await _resetDatabase();
  });

  group('#upsert', () {
    test(
      'given an object without id, then a new object with id is created',
      () async {
        var list = await dataModelRepository.find();
        expect(list.length, 0);

        final peerInfoName = 'New Task';
        final peerInfo = PeerInfo(
          name: peerInfoName,
          status: Status.active,
          publicKeyPem: '',
          locations: [PeerLocation('')],
        );
        await dataModelRepository.upsert(peerInfo);
        list = await dataModelRepository.find();
        expect(list.length, 1);
        expect(list.first.name, peerInfoName);
        expect(list.first.id, isNotNull);
      },
    );

    test(
      'given an object with an id which already exists, then the object is updated',
      () async {
        final peerInfoId = Uuid().v4();
        await dataModelRepository.upsert(
          PeerInfo(
            id: peerInfoId,
            name: '',
            status: Status.active,
            publicKeyPem: '',
            locations: [PeerLocation('')],
          ),
        );
        var list = await dataModelRepository.find();
        expect(list.length, 1);
        expect(list.first.name, '');
        expect(list.first.id, peerInfoId);

        final peerInfoName = 'New Task';
        final peerInfo = PeerInfo(
          id: peerInfoId,
          name: peerInfoName,
          status: Status.active,
          publicKeyPem: '',
          locations: [PeerLocation('')],
        );
        await dataModelRepository.upsert(peerInfo);
        list = await dataModelRepository.find();
        expect(list.length, 1);
        expect(list.first.name, peerInfoName);
        expect(list.first.id, peerInfoId);
      },
    );

    test(
      'given an object with an id which does not exists yet, then the object is added',
      () async {
        var list = await dataModelRepository.find();
        expect(list.length, 0);

        final peerInfoId = Uuid().v4();
        final peerInfoName = 'New Task';
        final peerInfo = PeerInfo(
          id: peerInfoId,
          name: peerInfoName,
          status: Status.active,
          publicKeyPem: '',
          locations: [PeerLocation('')],
        );
        await dataModelRepository.upsert(peerInfo);
        list = await dataModelRepository.find();
        expect(list.length, 1);
        expect(list.first.name, peerInfoName);
        expect(list.first.id, peerInfoId);
      },
    );
  });

  group('#transaction', () {
    test('execute', () async {
      final peerInfos = [
        PeerInfo(
          name: 'info1',
          status: Status.created,
          publicKeyPem: '',
          locations: [],
        ),
        PeerInfo(
          name: 'info2',
          status: Status.created,
          publicKeyPem: '',
          locations: [],
        ),
      ];
      await dataModelRepository.runTransaction((DatabaseClient txn) async {
        await Future.wait(peerInfos
            .map((peerInfo) => dataModelRepository.upsert(peerInfo, txn: txn)));
      });

      final entries = await dataModelRepository.find();
      expect(entries.toSet(), peerInfos.toSet());
    });
  });
}
