import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/utils/key_value_repository.dart';

import 'sync_service_test.mocks.dart';

@GenerateMocks([KeyValueRepository])
void main() {
  late MockKeyValueRepository keyValueRepository;
  late SyncService syncService;

  setUp(() async {
    keyValueRepository = MockKeyValueRepository();
    syncService = SyncService(keyValueRepository);
  });

  test('should sync after interval', () async {
    when(keyValueRepository.get<int>(SyncService.syncIntervalKey))
        .thenAnswer((_) => Future.value(1));
    when(keyValueRepository.get<bool>(SyncService.syncOnStartKey))
        .thenAnswer((_) => Future.value(false));
    var ran = false;

    fakeAsync((async) {
      syncService.startJob(() => ran = true);
      async.elapse(Duration(seconds: 1));
    });

    expect(ran, true);
  });

  test('should sync with new interval', () async {
    when(keyValueRepository.get<int>(SyncService.syncIntervalKey))
        .thenAnswer((_) => Future.value(1));
    when(keyValueRepository.get<bool>(SyncService.syncOnStartKey))
        .thenAnswer((_) => Future.value(false));
    var ran = false;

    fakeAsync((async) {
      syncService.startJob(() => ran = true);
      when(keyValueRepository.get<int>(SyncService.syncIntervalKey))
          .thenAnswer((_) => Future.value(5));
      async.elapse(Duration(seconds: 1));
      expect(ran, false);
      async.elapse(Duration(seconds: 4));
    });

    expect(ran, true);
  });

  test('should not sync before interval', () async {
    when(keyValueRepository.get<int>(SyncService.syncIntervalKey))
        .thenAnswer((_) => Future.value(1));
    when(keyValueRepository.get<bool>(SyncService.syncOnStartKey))
        .thenAnswer((_) => Future.value(false));
    var ran = false;

    fakeAsync((async) {
      syncService.startJob(() => ran = true);
    });

    expect(ran, false);
  });

  test('should run job when syncOnUpdate is true', () async {
    when(keyValueRepository.get<int>(SyncService.syncIntervalKey))
        .thenAnswer((_) => Future.value(1));
    when(keyValueRepository.get<bool>(SyncService.syncOnStartKey))
        .thenAnswer((_) => Future.value(false));
    when(keyValueRepository.get<bool>(SyncService.syncOnUpdateKey))
        .thenAnswer((_) => Future.value(true));
    var ran = false;

    fakeAsync((async) {
      syncService.startJob(() => ran = true);
    });
    await syncService.run();

    expect(ran, true);
  });

  test('should not run job when syncOnUpdate is false', () async {
    when(keyValueRepository.get<int>(SyncService.syncIntervalKey))
        .thenAnswer((_) => Future.value(1));
    when(keyValueRepository.get<bool>(SyncService.syncOnStartKey))
        .thenAnswer((_) => Future.value(false));
    when(keyValueRepository.get<bool>(SyncService.syncOnUpdateKey))
        .thenAnswer((_) => Future.value(false));
    var ran = false;

    fakeAsync((async) {
      syncService.startJob(() => ran = true);
    });
    await syncService.run();

    expect(ran, false);
  });

  test('should run job when syncOnStart is true', () async {
    when(keyValueRepository.get<int>(SyncService.syncIntervalKey))
        .thenAnswer((_) => Future.value(1));
    when(keyValueRepository.get<bool>(SyncService.syncOnStartKey))
        .thenAnswer((_) => Future.value(true));
    when(keyValueRepository.get<bool>(SyncService.syncOnUpdateKey))
        .thenAnswer((_) => Future.value(false));
    var ran = false;

    fakeAsync((async) {
      syncService.startJob(() => ran = true);
    });
    await syncService.run();

    expect(ran, true);
  });
}
