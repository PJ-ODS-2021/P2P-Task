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

  test('should not sync when interval set to 0', () async {
    when(keyValueRepository.get<int>(SyncService.syncIntervalKey))
        .thenAnswer((_) => Future.value(1));
    when(keyValueRepository.get<bool>(SyncService.syncOnStartKey))
        .thenAnswer((_) => Future.value(false));
    when(keyValueRepository.put(any, any)).thenAnswer((_) => Future.value(0));
    var ran = false;

    fakeAsync((async) {
      syncService.startJob(() => ran = true);
      async.elapse(Duration(seconds: 1));
      expect(ran, true);
      ran = false;
      syncService.setInterval(0);
      async.elapse(Duration(seconds: 2));
    });

    expect(ran, false);
  });

  test('should sync with new interval', () async {
    when(keyValueRepository.get<int>(SyncService.syncIntervalKey))
        .thenAnswer((_) => Future.value(1));
    when(keyValueRepository.get<bool>(SyncService.syncOnStartKey))
        .thenAnswer((_) => Future.value(false));
    when(keyValueRepository.put(any, any)).thenAnswer((_) => Future.value(5));
    var ran = false;

    fakeAsync((async) {
      syncService.startJob(() => ran = true);
      syncService.setInterval(5);
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
    when(keyValueRepository.get<bool>(SyncService.syncOnUpdateKey))
        .thenAnswer((_) => Future.value(true));
    var ran = false;

    fakeAsync((async) {
      syncService.startJob(() => ran = true);
    });
    await syncService.run(runOnSyncOnUpdate: true);

    expect(ran, true);
  });

  test('should not run job when syncOnUpdate is false', () async {
    when(keyValueRepository.get<int>(SyncService.syncIntervalKey))
        .thenAnswer((_) => Future.value(1));
    when(keyValueRepository.get<bool>(SyncService.syncOnUpdateKey))
        .thenAnswer((_) => Future.value(false));
    var ran = false;

    fakeAsync((async) {
      syncService.startJob(() => ran = true);
    });
    await syncService.run(runOnSyncOnUpdate: true);

    expect(ran, false);
  });

  test('should run job when syncOnStart is true', () async {
    when(keyValueRepository.get<int>(SyncService.syncIntervalKey))
        .thenAnswer((_) => Future.value(1));
    when(keyValueRepository.get<bool>(SyncService.syncOnStartKey))
        .thenAnswer((_) => Future.value(true));
    var ran = false;

    fakeAsync((async) {
      syncService.startJob(() => ran = true);
    });
    await syncService.run(runOnSyncOnStart: true);

    expect(ran, true);
  });

  test('should not run job when syncOnStart is false', () async {
    when(keyValueRepository.get<int>(SyncService.syncIntervalKey))
        .thenAnswer((_) => Future.value(1));
    when(keyValueRepository.get<bool>(SyncService.syncOnStartKey))
        .thenAnswer((_) => Future.value(false));
    var ran = false;

    fakeAsync((async) {
      syncService.startJob(() => ran = true);
    });
    await syncService.run(runOnSyncOnStart: true);

    expect(ran, false);
  });

  test('should run job when syncAfterDeviceAdded is true', () async {
    when(keyValueRepository.get<int>(SyncService.syncIntervalKey))
        .thenAnswer((_) => Future.value(1));
    when(keyValueRepository.get<bool>(SyncService.syncAfterDeviceAddedKey))
        .thenAnswer((_) => Future.value(true));
    var ran = false;

    fakeAsync((async) {
      syncService.startJob(() => ran = true);
    });
    await syncService.run(runOnSyncAfterDeviceAdded: true);

    expect(ran, true);
  });

  test('should not run job when syncAfterDeviceAdded is false', () async {
    when(keyValueRepository.get<int>(SyncService.syncIntervalKey))
        .thenAnswer((_) => Future.value(1));
    when(keyValueRepository.get<bool>(SyncService.syncAfterDeviceAddedKey))
        .thenAnswer((_) => Future.value(false));
    var ran = false;

    fakeAsync((async) {
      syncService.startJob(() => ran = true);
    });
    await syncService.run(runOnSyncAfterDeviceAdded: true);

    expect(ran, false);
  });
}
