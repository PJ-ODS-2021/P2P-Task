import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/services/peer_info_service.dart';
import 'package:p2p_task/services/peer_service.dart';
import 'package:p2p_task/utils/log_mixin.dart';

class LoadProcess<T> {
  final T? data;

  bool get hasData => data != null;
  final String? error;

  bool get hasError => error != null;

  bool get isLoading => !hasData && !hasError;

  bool get hasStaleData => hasError && hasData;

  LoadProcess({this.data, this.error});

  LoadProcess<T> withError(String error) =>
      LoadProcess(error: error, data: data);

  LoadProcess<T> withData(T data) => LoadProcess(data: data, error: null);
}

class DeviceListViewModel with LogMixin {
  final PeerInfoService _peerInfoService;
  final PeerService _peerService;

  final peerInfos = ValueNotifier<LoadProcess<UnmodifiableListView<PeerInfo>>>(
    LoadProcess<UnmodifiableListView<PeerInfo>>(),
  );

  DeviceListViewModel(this._peerInfoService, this._peerService) {
    loadDevices();
  }

  void loadDevices() {
    _peerInfoService.devices.then((value) {
      peerInfos.value = peerInfos.value.withData(UnmodifiableListView(value));
    }).catchError((error) {
      peerInfos.value = peerInfos.value.withError(error);
    });
  }

  void addNewPeer(PeerInfo peerInfo) async {
    final storedPeerInfo = await _peerInfoService.upsert(peerInfo);
    sendIntroductionMessageToPeer(
      storedPeerInfo,
      storedPeerInfo.locations.first,
    );
    loadDevices();
  }

  void handleQrCodeRead(String qrContent) async {
    var values = qrContent.split(',');
    if (values.length < 5) {
      l.warning(
        'ignoring invalid qr content "$qrContent": less than 5 components',
      );

      return;
    }

    final peerInfo = PeerInfo(
      id: values[0],
      name: values[1],
      locations: [PeerLocation('ws://${values[2]}:${values[3]}')],
      publicKeyPem: values[4],
    );
    final storedPeerInfo = await _peerInfoService.upsert(peerInfo);
    sendIntroductionMessageToPeer(
      storedPeerInfo,
      storedPeerInfo.locations.first,
    );
    loadDevices();
  }

  void syncWithPeer(PeerInfo peer, {PeerLocation? location}) async {
    await _peerService.syncWithPeer(peer, location: location);
    loadDevices();
  }

  void upsert(PeerInfo peer) async {
    await _peerInfoService.upsert(peer);
    loadDevices();
  }

  void sendIntroductionMessageToPeer(
    PeerInfo peerInfo,
    PeerLocation location,
  ) async {
    await _peerService.sendIntroductionMessageToPeer(
      peerInfo,
      location: location,
    );
  }

  void remove(PeerInfo peer) async {
    await _peerService.sendDeletePeerMessageToPeer(peer);
    await _peerInfoService.remove(peer);
    loadDevices();
  }

  bool get showQrScannerButton {
    // Dependent on what platforms are supported by qr_code_scanner package.
    // Add more platforms when more support is added.
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return true;
      case TargetPlatform.android:
        return true;
      default:
        return false;
    }
  }

  void dispose() {
    peerInfos.dispose();
  }
}
