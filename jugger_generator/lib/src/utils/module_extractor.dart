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
      message: () => buildErrorMessage(
        error: JuggerErrorId.module_annotation_required,
        message:
            'The ${moduleClass.name} is missing an annotation ${j.module.runtimeType}.',
      ),
      element: moduleClass,
    );
    check(
      moduleClass.isAbstract,
      message: () => buildErrorMessage(
        error: JuggerErrorId.abstract_module,
        message: 'Module ${moduleClass.name} must be abstract',
      ),
      element: moduleClass,
    );
    check(
      moduleClass.isPublic,
      message: () => buildErrorMessage(
        error: JuggerErrorId.public_module,
        message: 'Module ${moduleClass.name} must be public.',
      ),
      element: moduleClass,
    );

    final List<ElementAnnotation> resolvedMetadata = moduleClass.metadata;
    check(
      resolvedMetadata.length == 1,
      message: () => buildErrorMessage(
        error: JuggerErrorId.multiple_module_annotations,
        message:
            'Multiple annotations on module ${moduleClass.name} not supported.',
      ),
      element: moduleClass,
    );

    final ElementAnnotation elementAnnotation = resolvedMetadata.first;
    check(
      !_modulesQueue.contains(elementAnnotation),
      message: () => buildErrorMessage(
        error: JuggerErrorId.circular_modules_dependency,
        message: 'Found circular included modules!',
      ),
      element: moduleClass,
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
