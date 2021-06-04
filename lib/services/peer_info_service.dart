import 'package:flutter/foundation.dart';
import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/utils/data_model_repository.dart';

class PeerInfoService extends ChangeNotifier {
  final DataModelRepository<PeerInfo> _repository;

  PeerInfoService(DataModelRepository<PeerInfo> repository)
      : this._repository = repository;

  Future<List<PeerInfo>> get devices async => await _repository.find();

  Future upsert(PeerInfo peerInfo) async {
    await _repository.upsert(peerInfo);
    notifyListeners();
  }

  Future remove(PeerInfo peerInfo) async {
    if (peerInfo.id == null) return;
    await _repository.remove(peerInfo.id!);
    notifyListeners();
  }
}
