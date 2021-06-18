import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/services/change_callback_provider.dart';
import 'package:p2p_task/utils/data_model_repository.dart';

class PeerInfoService with ChangeCallbackProvider {
  final DataModelRepository<PeerInfo> _repository;

  PeerInfoService(this._repository);

  Future<List<PeerInfo>> get devices async => await _repository.find();

  Future<void> upsert(PeerInfo peerInfo) async {
    await _repository.upsert(peerInfo);
    invokeChangeCallback();
  }

  Future<void> remove(PeerInfo peerInfo) async {
    if (peerInfo.id == null) return;
    await _repository.remove(peerInfo.id!);
    invokeChangeCallback();
  }
}
