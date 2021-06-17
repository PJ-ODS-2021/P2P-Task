import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceInfoService {
  final DeviceInfoPlugin _deviceInfoPlugin;

  DeviceInfoService(DeviceInfoPlugin? deviceInfoPlugin)
      : this._deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin();

  Future<String> get deviceName async {
    if (kIsWeb)
      return (await _deviceInfoPlugin.webBrowserInfo).userAgent;
    else if (Platform.isIOS)
      return (await _deviceInfoPlugin.iosInfo).model ?? 'iOS';
    else if (Platform.isAndroid)
      return (await _deviceInfoPlugin.androidInfo).model ?? 'Android';
    else if (Platform.isLinux)
      return (await _deviceInfoPlugin.linuxInfo).prettyName;
    else if (Platform.isMacOS)
      return (await _deviceInfoPlugin.macOsInfo).model;
    else if (Platform.isWindows)
      return (await _deviceInfoPlugin.windowsInfo).computerName;
    else
      return 'Unknown';
  }
}
