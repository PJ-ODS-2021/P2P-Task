import 'dart:async';

import 'package:p2p_task/services/change_callback_provider.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:p2p_task/utils/log_mixin.dart';
import 'package:pedantic/pedantic.dart';

class SyncService with LogMixin, ChangeCallbackProvider {
  static final String syncIntervalKey = 'syncInterval';
  static final int _syncIntervalDefaultValue = 5;
  static final String syncOnStartKey = 'syncOnStart';
  static final bool _syncOnStartDefaultValue = true;
  static final String syncOnUpdateKey = 'syncOnUpdate';
  static final bool _syncOnUpdateDefaultValue = true;

  final KeyValueRepository _settingsRepository;
  StreamSubscription? _syncJob;
  Function()? _job;

  SyncService(KeyValueRepository settingsRepository)
      : _settingsRepository = settingsRepository;

  Future<int> get interval async =>
      (await _settingsRepository.get<int>(syncIntervalKey)) ??
      _syncIntervalDefaultValue;

  Future<void> setInterval(int interval) async {
    final updatedInterval =
        await _settingsRepository.put(syncIntervalKey, interval);
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
    if (await syncOnStart) await run();
    if (_syncJob != null) await _syncJob!.cancel();
    _syncJob = Stream.periodic(Duration(seconds: 1), (count) => count)
        .listen((count) async {
      unawaited(_runJob(count));
    });
  }

  Future<void> run() async {
    if (_job == null) return;
    if (await syncOnStart || await syncOnUpdate) {
      l.info('Syncing job started...');
      _job!();
    }
  }

  Future<void> _runJob(int count) async {
    final currentInterval = await interval;
    if (currentInterval < 1) return;
    if ((count + 1) % currentInterval == 0) {
      l.info('Syncing job started...');
      _job!();
    }
  }
}
