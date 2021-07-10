import 'dart:async';

import 'package:p2p_task/services/change_callback_provider.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:p2p_task/utils/log_mixin.dart';

class SyncService with LogMixin, ChangeCallbackProvider {
  static final String syncIntervalKey = 'syncInterval';
  static final int _syncIntervalDefault = 60;
  static final String syncOnStartKey = 'syncOnStart';
  static final bool _syncOnStartDefault = true;
  static final String syncOnUpdateKey = 'syncOnUpdate';
  static final bool _syncOnUpdateDefault = true;
  static final String syncAfterDeviceAddedKey = 'syncAfterDeviceAdded';
  static final bool _syncAfterDeviceAddedDefault = true;

  final KeyValueRepository _settingsRepository;
  Timer? _syncTimer;
  Function()? _job;

  SyncService(KeyValueRepository settingsRepository)
      : _settingsRepository = settingsRepository;

  Future<int> get interval async =>
      (await _settingsRepository.get<int>(syncIntervalKey)) ??
      _syncIntervalDefault;

  Future<void> setInterval(int interval) async {
    final updatedInterval =
        await _settingsRepository.put(syncIntervalKey, interval, true);
    await _updateSyncTimer(updatedInterval);
    invokeChangeCallback();

    return updatedInterval;
  }

  Future<bool> get syncOnStart async =>
      (await _settingsRepository.get<bool>(syncOnStartKey)) ??
      _syncOnStartDefault;

  Future<void> setSyncOnStart(bool syncOnStart) async {
    final updatedValue =
        await _settingsRepository.put(syncOnStartKey, syncOnStart, true);
    invokeChangeCallback();

    return updatedValue;
  }

  Future<bool> get syncOnUpdate async =>
      (await _settingsRepository.get<bool>(syncOnUpdateKey)) ??
      _syncOnUpdateDefault;

  Future<void> setSyncOnUpdate(bool syncOnUpdate) async {
    final updatedValue =
        await _settingsRepository.put(syncOnUpdateKey, syncOnUpdate, true);
    invokeChangeCallback();

    return updatedValue;
  }

  Future<bool> retrieveSyncAfterDeviceAdded() async =>
      (await _settingsRepository.get<bool>(syncAfterDeviceAddedKey)) ??
      _syncAfterDeviceAddedDefault;

  Future<void> setSyncAfterDeviceAdded(bool syncAfterDeviceAdded) async {
    final updatedValue = await _settingsRepository.put(
      syncAfterDeviceAddedKey,
      syncAfterDeviceAdded,
      true,
    );
    invokeChangeCallback();

    return updatedValue;
  }

  Future<void> startJob(Function() job) async {
    _job = job;
    await _updateSyncTimer(await interval);
  }

  Future<void> run({
    bool runOnSyncOnStart = false,
    bool runOnSyncOnUpdate = false,
    bool runOnSyncAfterDeviceAdded = false,
  }) async {
    if (_job == null) return;
    final conditions = [
      runOnSyncOnStart ? await syncOnStart : false,
      runOnSyncOnUpdate ? await syncOnUpdate : false,
      runOnSyncAfterDeviceAdded ? await retrieveSyncAfterDeviceAdded() : false,
    ];
    if (conditions.any((element) => element)) {
      _runJob();
    }
  }

  Future<void> clearJob() async {
    if (_syncTimer != null) {
      _syncTimer?.cancel();
      _syncTimer = null;
    }
    _job = null;
  }

  Future<void> _updateSyncTimer(int interval) async {
    if (_syncTimer != null) _syncTimer!.cancel();
    if (_job == null || interval == 0) return;
    _syncTimer = Timer.periodic(Duration(seconds: interval), (_) {
      _runJob();
    });
  }

  void _runJob() {
    logger.info('Syncing job started...');
    _job!();
  }
}
