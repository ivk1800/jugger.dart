import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';

import '../builder/global_config.dart';
import 'type_name_registry.dart';
import 'unique_name_registry.dart';
import 'wrappers.dart';

abstract class AssetContext {
  GlobalConfig get globalConfig;

  Allocator get allocator;

  TypeNameGenerator get typeNameGenerator;

  UniqueIdGenerator get uniqueIdGenerator;

  LibraryElement get lib;

  ComponentBuilder? getComponentBuilderOf(DartType type);
}
