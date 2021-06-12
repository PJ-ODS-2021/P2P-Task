import 'dart:async';

import 'package:p2p_task/services/change_callback_provider.dart';
import 'package:p2p_task/utils/key_value_repository.dart';
import 'package:p2p_task/utils/log_mixin.dart';

class SyncService with LogMixin, ChangeCallbackProvider {
  final String _syncIntervalKey = 'syncInterval';
  final int _syncIntervalDefaultValue = 15;
  final String _syncOnStartKey = 'syncOnStart';
  final String _syncOnUpdateKey = 'syncOnUpdate';

  KeyValueRepository _repository;
  // ignore: cancel_subscriptions
  StreamSubscription? _syncJob;
  Function()? _job;

  SyncService(KeyValueRepository repository) : this._repository = repository;

  Future<int> get interval async =>
      (await _repository.get<int>(_syncIntervalKey)) ??
      _syncIntervalDefaultValue;

  Future setInterval(int interval) async {
    final updatedInterval = await _repository.put(_syncIntervalKey, interval);
    invokeChangeCallback();
    return updatedInterval;
  }

  Future<bool> get syncOnStart async =>
      (await _repository.get<bool>(_syncOnStartKey)) ?? true;

  Future setSyncOnStart(bool syncOnStart) async {
    final updatedValue = await _repository.put(_syncOnStartKey, syncOnStart);
    invokeChangeCallback();
    return updatedValue;
  }

  Future<bool> get syncOnUpdate async =>
      (await _repository.get<bool>(_syncOnUpdateKey)) ?? true;

  Future setSyncOnUpdate(bool syncOnUpdate) async {
    final updatedValue = await _repository.put(_syncOnUpdateKey, syncOnUpdate);
    invokeChangeCallback();
    return updatedValue;
  }

  Future startJob(Function() job) async {
    _job = job;
    if (_syncJob != null) await _syncJob!.cancel();
    final currentInterval = await interval;
    if (currentInterval < 1) return;
    if (await syncOnStart && currentInterval > 1) job();
    _syncJob = Stream.periodic(Duration(seconds: 1), (count) => count)
        .listen((count) async {
      _runJob(count);
    });
  }

  Future run() async {
    if (_job != null && await syncOnUpdate) _job!();
  }

  Future _runJob(int count) async {
    final currentInterval = await interval;
    if (currentInterval < 1) return;
    if (count % currentInterval == 0) {
      l.info('Syncing job started...');
      _job!();
    }
  }
}
