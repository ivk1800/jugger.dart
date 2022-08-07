import 'package:analyzer/dart/element/element.dart';

import '../component_context.dart';

abstract class ParentComponentProvider {
  String get componentName;

  ClassElement get componentClassElement;

  List<ParentComponentInfo> get fullInfo;
}
