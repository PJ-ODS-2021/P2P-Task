import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/services/change_callback_provider.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/utils/data_model_repository.dart';

class PeerInfoService with ChangeCallbackProvider {
  final DataModelRepository<PeerInfo> _repository;
  final SyncService? _syncService;

  PeerInfoService(this._repository, this._syncService);

  Future<List<PeerInfo>> get devices async => await _repository.find();

  Future<List<PeerInfo>> get activeDevices async => (await devices)
      .where((device) => device.status == Status.active)
      .toList();

  Future<Map<String, String>> get deviceNameMap async =>
      Map.fromEntries((await devices)
          .where((peerInfo) => peerInfo.id != null && peerInfo.name.isNotEmpty)
          .map((peerInfo) => MapEntry(peerInfo.id!, peerInfo.name)));

  Future<void> upsert(
    PeerInfo peerInfo, {
    bool mergePeerLocations = true,
  }) async {
    if (mergePeerLocations && peerInfo.id != null) {
      await _repository.runTransaction((txn) async {
        final existentPeerInfo = await _repository.get(peerInfo.id!, txn: txn);
        if (existentPeerInfo != null) {
          existentPeerInfo.locations
              .forEach((location) => peerInfo.addPeerLocation(location));
        }
        await _repository.upsert(peerInfo, txn: txn);
      });
    } else {
      await _repository.upsert(peerInfo);
    }

    await _syncService?.run(runOnSyncAfterDeviceAdded: true);
    invokeChangeCallback();
  }

  Future<void> update(
    String? id,
    PeerInfo? Function(PeerInfo?) updateFunc,
  ) async {
    if (id == null) {
      final peerInfo = updateFunc(null);
      if (peerInfo != null) await _repository.upsert(peerInfo);
    } else {
      await _repository.runTransaction((txn) async {
        var peerInfo = await _repository.get(id, txn: txn);
        final existed = peerInfo != null;
        peerInfo = updateFunc(peerInfo);
        if (peerInfo == null) {
          if (existed) await _repository.remove(id, txn: txn);
        } else {
          peerInfo.id ??= id;
          if (peerInfo.id != id) await _repository.remove(id, txn: txn);
          await _repository.upsert(peerInfo, txn: txn);
        }
      });
    }
    invokeChangeCallback();
  }

  Future<PeerInfo?> getById(String id) async => await _repository.get(id);

  Future<void> remove(String? id) async {
    if (id == null) return;
    await _repository.remove(id);
    invokeChangeCallback();
  }
}
