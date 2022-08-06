import 'package:flutter/material.dart';
import 'package:flutter_example/src/common/logger.dart';
import 'package:jugger/jugger.dart';

class ConsoleLogger implements Logger {
  @inject
  const ConsoleLogger();

  @override
  void d(String message) {
    debugPrint(message);
  }
}
