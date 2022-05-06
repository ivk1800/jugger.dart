import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';

import 'classes.dart';
import 'jugger_error.dart';
import 'messages.dart';
import 'utils.dart';

class ModuleExtractor {
  final Queue<ElementAnnotation> _modulesQueue = Queue<ElementAnnotation>();

  List<ModuleAnnotation> getIncludes(ElementAnnotation elementAnnotation) {
    final List<ClassElement> modules =
        getClassListFromField(elementAnnotation, 'includes');

    final List<ModuleAnnotation> map = modules.map((ClassElement moduleClass) {
      return getModuleAnnotationOfModuleClass(moduleClass);
    }).toList();
    return map;
  }

  ModuleAnnotation getModuleAnnotationOfModuleClass(Element moduleClass) {
    if (moduleClass is! ClassElement) {
      throw JuggerError('element[$moduleClass] is not ClassElement');
    }
    check(moduleClass.isAbstract, () => moduleMustBeAbstract(moduleClass));
    check(moduleClass.isPublic, () => publicModule(moduleClass));
    check(
      moduleClass.hasAnnotatedAsModule(),
      () => moduleAnnotationRequired(moduleClass),
    );

    final List<ElementAnnotation> resolvedMetadata = moduleClass.metadata;
    check(
      resolvedMetadata.length == 1,
      () => 'multiple annotations on module not supported',
    );

    final ElementAnnotation elementAnnotation = resolvedMetadata.first;
    if (_modulesQueue.contains(elementAnnotation)) {
      throw JuggerError('Found circular included modules!');
    }

    _modulesQueue.addFirst(elementAnnotation);
    final ModuleAnnotation moduleAnnotation = ModuleAnnotation(
      moduleElement: moduleClass,
      includes: getIncludes(elementAnnotation),
    );
    _modulesQueue.removeFirst();
    return moduleAnnotation;
  }
}
