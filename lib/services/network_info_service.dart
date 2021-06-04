import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class NetworkInfoService extends ChangeNotifier {
  late List<String> _ips = [];
  final NetworkInfo _networkInfo;
  final Permission _permission;

  NetworkInfoService(NetworkInfo? networkInfo, Permission? permission)
      : _networkInfo = networkInfo ?? NetworkInfo(),
        _permission = permission ?? Permission.location {
    _initIps();
  }

  UnmodifiableListView<String> get ips => UnmodifiableListView(_ips);

  Future<String> get ssid async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return 'Unknown';
    if (Platform.isAndroid && !await _permission.isGranted) {
      final status = await _permission.request();
      if (status.isGranted) return 'Unknown';
    }
    if (Platform.isIOS) {
      final status = await _networkInfo.getLocationServiceAuthorization();
      if (status.index == 0) {
        await _networkInfo.requestLocationServiceAuthorization();
      } else if (status.index == 1) {
        return 'Unknown';
      }
    }
    return await _networkInfo.getWifiName() ?? 'Unknown';
  }

  void _initIps() async {
    if (kIsWeb) return;

    try {
      final wifiIP = await _networkInfo.getWifiIP();
      final networkInterfaces =
          await NetworkInterface.list(type: InternetAddressType.IPv4);
      _ips = [
        ...networkInterfaces
            .fold<List<InternetAddress>>(<InternetAddress>[],
                (previousValue, e) => previousValue..addAll(e.addresses))
            .where((e) => !e.isMulticast)
            .map((e) => e.address)
      ];
      if (!(wifiIP == null ||
          wifiIP.isEmpty ||
          wifiIP == '0.0.0.0' ||
          _ips.contains(wifiIP))) _ips.add(wifiIP);
    } on PlatformException catch (e) {
      print(e.toString());
    }
    notifyListeners();
  }
}
