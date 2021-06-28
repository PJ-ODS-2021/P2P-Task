import 'dart:async';

import 'package:p2p_task/services/change_callback_provider.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:p2p_task/utils/log_mixin.dart';

class SyncService with LogMixin, ChangeCallbackProvider {
  static final String syncIntervalKey = 'syncInterval';
  static final int _syncIntervalDefaultValue = 5;
  static final String syncOnStartKey = 'syncOnStart';
  static final bool _syncOnStartDefaultValue = true;
  static final String syncOnUpdateKey = 'syncOnUpdate';
  static final bool _syncOnUpdateDefaultValue = true;

  final KeyValueRepository _settingsRepository;
  Timer? _syncTimer;
  Function()? _job;

  SyncService(KeyValueRepository settingsRepository)
      : _settingsRepository = settingsRepository;

  Future<int> get interval async =>
      (await _settingsRepository.get<int>(syncIntervalKey)) ??
      _syncIntervalDefaultValue;

  Future<void> setInterval(int interval) async {
    final updatedInterval =
        await _settingsRepository.put(syncIntervalKey, interval);
    await _updateSyncTimer(updatedInterval);
    invokeChangeCallback();

    return updatedInterval;
  }

  Future<bool> get syncOnStart async =>
      (await _settingsRepository.get<bool>(syncOnStartKey)) ??
      _syncOnStartDefaultValue;

  Future<void> setSyncOnStart(bool syncOnStart) async {
    final updatedValue =
        await _settingsRepository.put(syncOnStartKey, syncOnStart);
    invokeChangeCallback();

    return updatedValue;
  }

  Future<bool> get syncOnUpdate async =>
      (await _settingsRepository.get<bool>(syncOnUpdateKey)) ??
      _syncOnUpdateDefaultValue;

  Future<void> setSyncOnUpdate(bool syncOnUpdate) async {
    final updatedValue =
        await _settingsRepository.put(syncOnUpdateKey, syncOnUpdate);
    invokeChangeCallback();

    return updatedValue;
  }

  Future<void> startJob(Function() job) async {
    _job = job;
    await _updateSyncTimer(await interval);
    if (await syncOnStart) _runJob();
  }

  Future<void> run() async {
    if (_job == null) return;
    if (await syncOnStart || await syncOnUpdate) {
      _runJob();
    }
  }

  Future<void> _updateSyncTimer(int interval) async {
    if (_syncTimer != null) _syncTimer!.cancel();
    if (_job == null || interval == 0) return;
    _syncTimer = Timer.periodic(Duration(seconds: interval), (_) {
      _runJob();
    });
  }

  void _runJob() {
    l.info('Syncing job started...');
    _job!();
  }
}
