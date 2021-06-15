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

  Future<void> addPeerLocation(PeerInfo peerInfo, PeerLocation location) async {
    // TODO: make this function work in a concurrent environment

    if (peerInfo.id == null) return upsert(peerInfo..addPeerLocation(location));
    final existingPeerInfo = await _repository.get(peerInfo.id!);
    if (existingPeerInfo == null)
      return upsert(peerInfo..addPeerLocation(location));

    // use new name if it not emty
    existingPeerInfo.name =
        peerInfo.name.isEmpty ? existingPeerInfo.name : peerInfo.name;

    existingPeerInfo.addPeerLocation(location);
    return upsert(existingPeerInfo);
  }

  Future<void> remove(PeerInfo peerInfo) async {
    if (peerInfo.id == null) return;
    await _repository.remove(peerInfo.id!);
    invokeChangeCallback();
  }
}
