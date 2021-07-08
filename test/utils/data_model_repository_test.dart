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
}
