import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

class Helper {
  static getDeviceModel() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.model; // device model on iOS
    } else if (Platform.isAndroid) {
      AndroidDeviceInfo androidDeviceInfo = await deviceInfo.androidInfo;
      return androidDeviceInfo.model; // device model on Android
    } else if (Platform.isWindows) {
      WindowsDeviceInfo windowDeviceInfo = await deviceInfo.windowsInfo;
      return windowDeviceInfo.computerName;
    } else if (Platform.isMacOS) {
      MacOsDeviceInfo macosDeviceInfo = await deviceInfo.macOsInfo;
      return macosDeviceInfo.model; // device model on macOS
    }
  }
}

class Layout {
  static width(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static height(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static statusbarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  static isPhone(BuildContext context) {
    var deviceSize = MediaQuery.of(context).size.shortestSide;
    return (deviceSize < 600) ? true : false;
  }

  static deviceSize(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide;
  }
}
