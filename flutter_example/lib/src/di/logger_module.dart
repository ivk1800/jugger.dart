import 'package:jugger/jugger.dart';

import '../common/composite_logger.dart';
import '../common/console_logger.dart';
import '../common/file_logger.dart';
import '../common/logger.dart';

@module
abstract class LoggerModule {
  @binds
  @singleton
  @intoSet
  Logger bindFileLogger(FileLogger impl);

  @binds
  @singleton
  @intoSet
  Logger bindConsoleLogger(ConsoleLogger impl);

  @binds
  @singleton
  Logger bindLogger(CompositeLogger impl);
}
