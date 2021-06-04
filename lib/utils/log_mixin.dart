import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

mixin LogMixin on Object {
  static const String GREY = '\x1B[37m';
  static const String RESET = '\x1B[0m';
  static Map<String, Logger> _logger = {};

  String get _className => this.runtimeType.toString();
  late final Logger l = _logger[_className] ?? createLogger();

  createLogger() {
    _logger[_className] = Logger(_className)..clearListeners();
    if (kReleaseMode ||
        (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')))
      return _logger[_className];

    return _logger[_className]!
      ..onRecord.listen(
        (record) {
          debugPrint(
              '$GREY[${record.level.name}]$RESET ${record.time} $GREY${record.loggerName}$RESET: ${record.message}' +
                  (record.error != null
                      ? '\n$GREY>$RESET ${record.error}'
                      : '') +
                  (record.stackTrace != null
                      ? '\n$GREY>$RESET ${record.stackTrace}'
                      : ''));
        },
      );
  }
}
