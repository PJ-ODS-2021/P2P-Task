import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';

class NetworkInfoService extends ChangeNotifier {
  late List<String> _ips = [];
  final NetworkInfo _networkInfo;

  NetworkInfoService(NetworkInfo? networkInfo)
      : _networkInfo = networkInfo ?? NetworkInfo() {
    _initIps();
  }

  List<String> get ips => UnmodifiableListView(_ips);

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
