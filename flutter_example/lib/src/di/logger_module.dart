import 'package:jugger/jugger.dart';

import '../common/composite_logger.dart';
import '../common/console_logger.dart';
import '../common/file_logger.dart';
import '../common/logger.dart';
import 'scope.dart';

@module
abstract class LoggerModule {
  @binds
  @applicationScope
  @intoSet
  Logger bindFileLogger(FileLogger impl);

  @binds
  @applicationScope
  @intoSet
  Logger bindConsoleLogger(ConsoleLogger impl);

  @binds
  @applicationScope
  Logger bindLogger(CompositeLogger impl);
}
