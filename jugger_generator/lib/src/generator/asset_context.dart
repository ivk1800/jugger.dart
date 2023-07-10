import 'package:code_builder/code_builder.dart';

import '../builder/global_config.dart';
import 'component_circular_dependency_detector.dart';
import 'unique_name_registry.dart';

abstract class AssetContext {
  GlobalConfig get globalConfig;

  Allocator get allocator;

  DartEmitter get emitter;

  UniqueIdGenerator get uniqueIdGenerator;

  ComponentCircularDependencyDetector get componentCircularDependencyDetector;
}
