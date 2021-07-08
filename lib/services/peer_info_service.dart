import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/services/change_callback_provider.dart';
import 'package:p2p_task/services/sync_service.dart';
import 'package:p2p_task/utils/data_model_repository.dart';

class PeerInfoService with ChangeCallbackProvider {
  final DataModelRepository<PeerInfo> _repository;
  final SyncService? _syncService;

  PeerInfoService(this._repository, this._syncService);

  Future<List<PeerInfo>> get devices async => await _repository.find();

  Future<Map<String, String>> get deviceNameMap async =>
      Map.fromEntries((await devices)
          .where((peerInfo) => peerInfo.id != null && peerInfo.name.isNotEmpty)
          .map((peerInfo) => MapEntry(peerInfo.id!, peerInfo.name)));

  Future<void> upsert(PeerInfo peerInfo) async {
    await _repository.upsert(peerInfo);
    await _syncService?.run(runOnSyncAfterDeviceAdded: true);
    invokeChangeCallback();
  }

  Future<void> remove(PeerInfo peerInfo) async {
    if (peerInfo.id == null) return;
    await _repository.remove(peerInfo.id!);
    invokeChangeCallback();
  }
}
