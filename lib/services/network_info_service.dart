import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:p2p_task/services/change_callback_provider.dart';
import 'package:p2p_task/utils/log_mixin.dart';
import 'package:permission_handler/permission_handler.dart';

class NetworkInfoService with LogMixin, ChangeCallbackProvider {
  late List<String> _ips = [];
  Completer<String?>? _ssidCompleter;

  NetworkInfoService() {
    _initIps();
  }

  UnmodifiableListView<String> get ips => UnmodifiableListView(_ips);

  Future<String?> get ssid {
    l.info('request for getting ssid');
    if (_ssidCompleter != null && !_ssidCompleter!.isCompleted) {
      l.warning('waiting for previous ssid request to finish');

      return _ssidCompleter!.future.then((value) {
        l.info('completer finished with ssid: "$value"');

        return value;
      });
    }
    _ssidCompleter = Completer();

    return _detectSsid().then((value) {
      l.info('detected ssid: "$value"');
      _ssidCompleter?.complete(value);

      return value;
    });
  }

  Future<String?> _detectSsid() async {
    l.info('detecting ssid');
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return null;

    final networkInfo = NetworkInfo();
    if (Platform.isAndroid) {
      // should only be necessary for android 8.0 onwards
      if (!(await Permission.location.request()).isGranted) return null;
    } else if (Platform.isIOS) {
      final status = await networkInfo.getLocationServiceAuthorization();
      if (status.index == 0) {
        await networkInfo.requestLocationServiceAuthorization();
      } else if (status.index == 1) {
        return null;
      }
    }

    return networkInfo.getWifiName();
  }

  void _initIps() async {
    if (kIsWeb) return;

    try {
      final wifiIp = await NetworkInfo().getWifiIP();
      final networkInterfaces =
          await NetworkInterface.list(type: InternetAddressType.IPv4);
      _ips = [
        ...networkInterfaces
            .fold<List<InternetAddress>>(
              <InternetAddress>[],
              (previousValue, e) => previousValue..addAll(e.addresses),
            )
            .where((e) => !e.isMulticast)
            .map((e) => e.address),
      ];
      if (wifiIp != null && ipValid(wifiIp) && !_ips.contains(wifiIp)) {
        _ips.add(wifiIp);
      }
    } on PlatformException catch (e) {
      l.severe(e.toString());
    }
    invokeChangeCallback();
  }

  static bool ipValid(String ip) {
    return ip.isNotEmpty && ip != '0.0.0.0';
  }
}
