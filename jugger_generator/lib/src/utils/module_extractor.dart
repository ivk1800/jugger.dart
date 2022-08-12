import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:jugger/jugger.dart' as j;

import '../errors_glossary.dart';
import '../generator/wrappers.dart';
import '../jugger_error.dart';
import 'element_annotation_ext.dart';
import 'utils.dart';

/// Helper class that detects circular dependencies between modules.
class ModuleExtractor {
  final Queue<ElementAnnotation> _modulesQueue = Queue<ElementAnnotation>();

  List<ModuleAnnotation> getIncludes(ElementAnnotation elementAnnotation) {
    final List<ClassElement> modules =
        getClassListFromField(elementAnnotation, 'includes');

    final List<ModuleAnnotation> map =
        modules.map(getModuleAnnotationOfModuleClass).toList();
    return map;
  }

  ModuleAnnotation getModuleAnnotationOfModuleClass(Element moduleClass) {
    if (moduleClass is! ClassElement) {
      throw UnexpectedJuggerError('element[$moduleClass] is not ClassElement');
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
      () => buildErrorMessage(
        error: JuggerErrorId.multiple_module_annotations,
        message:
            'Multiple annotations on module ${moduleClass.name} not supported.',
      ),
    );

    final ElementAnnotation elementAnnotation = resolvedMetadata.first;
    check(
      !_modulesQueue.contains(elementAnnotation),
      () => buildErrorMessage(
        error: JuggerErrorId.circular_modules_dependency,
        message: 'Found circular included modules!',
      ),
    );

    _modulesQueue.addFirst(elementAnnotation);
    final ModuleAnnotation moduleAnnotation = ModuleAnnotation(
      moduleElement: moduleClass,
      includes: getIncludes(elementAnnotation),
    );
    _modulesQueue.removeFirst();
    return moduleAnnotation;
  }
}
