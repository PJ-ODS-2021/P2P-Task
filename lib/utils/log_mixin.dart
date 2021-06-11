import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

mixin LogMixin {
  static const String WHITE = '\x1B[37m';
  static const String YELLOW = '\x1B[33m';
  static const String RED = '\x1B[31m';
  static const String RESET = '\x1B[0m';
  static final Map<String, Logger> _loggers = {};

  String get _className => runtimeType.toString();

  late final Logger l = _loggers[_className] ?? createLogger();

  static bool get _useColoredDebugPrint =>
      !kReleaseMode &&
      (kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST'));

  Logger createLogger() {
    final logger = _loggers[_className] = Logger(_className)..clearListeners();
    if (_useColoredDebugPrint) logger.onRecord.listen(_coloredPrint);

    return logger;
  }

  void _coloredPrint(LogRecord record) {
    final levelColor = record.level <= Level.INFO
        ? WHITE
        : (record.level <= Level.WARNING ? YELLOW : RED);
    debugPrint(
      '$levelColor[${record.level.name}]$RESET ${record.time} $WHITE${record.loggerName}$RESET: ${record.message}' +
          (record.error != null ? '\n$WHITE>$RESET ${record.error}' : '') +
          (record.stackTrace != null
              ? '\n$WHITE>$RESET ${record.stackTrace}'
              : ''),
    );
  }
}
