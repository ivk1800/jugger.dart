import 'package:flutter_example/src/common/logger.dart';
import 'package:jugger/jugger.dart';

class CompositeLogger implements Logger {
  @inject
  const CompositeLogger(this.loggers);

  final Set<Logger> loggers;

  @override
  void d(String message) {
    for (final Logger logger in loggers) {
      logger.d(message);
    }
  }
}
