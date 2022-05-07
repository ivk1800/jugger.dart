import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';

import 'classes.dart';
import 'errors_glossary.dart';
import 'package:jugger/jugger.dart' as j;
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
    check(
      moduleClass.hasAnnotatedAsModule(),
      () => buildErrorMessage(
        error: JuggerErrorId.module_annotation_required,
        message:
            'The ${moduleClass.name} is missing an annotation ${j.module.runtimeType}.',
      ),
    );
    check(
      moduleClass.isAbstract,
      () => buildErrorMessage(
        error: JuggerErrorId.abstract_module,
        message: 'Module ${moduleClass.name} must be abstract',
      ),
    );
    check(
      moduleClass.isPublic,
      () => buildErrorMessage(
        error: JuggerErrorId.public_module,
        message: 'Module ${moduleClass.name} must be public.',
      ),
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
