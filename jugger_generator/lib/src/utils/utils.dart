import 'dart:convert';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:jugger/jugger.dart';

import '../errors_glossary.dart';
import '../generator/tag.dart';
import '../generator/wrappers.dart';
import '../jugger_error.dart';
import 'library_ext.dart';
import 'module_extractor.dart';

ComponentAnnotation? getComponentAnnotation(Element element) {
  final Annotation? annotation = getAnnotations(element)
      .firstWhereOrNull((Annotation a) => a is ComponentAnnotation);
  return annotation is ComponentAnnotation ? annotation : null;
}

ComponentBuilderAnnotation? getComponentBuilderAnnotation(Element element) {
  final Annotation? annotation = getAnnotations(element)
      .firstWhereOrNull((Annotation a) => a is ComponentBuilderAnnotation);
  return annotation is ComponentBuilderAnnotation ? annotation : null;
}

BindAnnotation? getBindAnnotation(Element element) {
  final Annotation? annotation = getAnnotations(element)
      .firstWhereOrNull((Annotation a) => a is BindAnnotation);
  return annotation is BindAnnotation ? annotation : null;
}

NonLazyAnnotation? getNonLazyAnnotation(Element element) {
  final Annotation? annotation = getAnnotations(element)
      .firstWhereOrNull((Annotation a) => a is NonLazyAnnotation);
  return annotation is NonLazyAnnotation ? annotation : null;
}

ProvideAnnotation? getProvideAnnotation(Element element) {
  final Annotation? annotation = getAnnotations(element)
      .firstWhereOrNull((Annotation a) => a is ProvideAnnotation);
  return annotation is ProvideAnnotation ? annotation : null;
}

QualifierAnnotation? getQualifierAnnotation(Element element) {
  final List<QualifierAnnotation> qualifierAnnotation =
      getAnnotations(element).whereType<QualifierAnnotation>().toList();
  check(
    qualifierAnnotation.length <= 1,
    () => buildErrorMessage(
      error: JuggerErrorId.multiple_qualifiers,
      message:
          'Multiple qualifiers of ${element.enclosingElement?.name}.${element.name} not allowed.',
    ),
  );

  return qualifierAnnotation
      .firstWhereOrNull((Annotation a) => a is QualifierAnnotation);
}

String generateMd5(String input) => md5.convert(utf8.encode(input)).toString();

List<Annotation> getAnnotations(Element moduleClass) {
  final List<Annotation> annotations = <Annotation>[];

  for (int i = 0; i < moduleClass.metadata.length; i++) {
    final ElementAnnotation annotation = moduleClass.metadata[i];

    final Element? annotationElement = annotation.element;

    if (annotationElement is PropertyAccessorElement) {
      final ClassElement annotationClassElement =
          annotationElement.variable.type.element! as ClassElement;
      final bool isQualifier = annotationClassElement.metadata.isQualifier();

      if (isQualifier) {
        annotations.add(
          QualifierAnnotation(tag: _getTag(annotation, annotationClassElement)),
        );
      }
    } else if (annotationElement is ConstructorElement) {
      final ClassElement annotationClassElement =
          annotationElement.enclosingElement;
      final bool isQualifier = annotationClassElement.metadata.isQualifier();
      if (isQualifier) {
        annotations.add(
          QualifierAnnotation(tag: _getTag(annotation, annotationClassElement)),
        );
      }
    }
  }

  final List<ElementAnnotation> resolvedMetadata = moduleClass.metadata;

  for (int i = 0; i < resolvedMetadata.length; i++) {
    final ElementAnnotation annotation = resolvedMetadata[i];
    final Element? valueElement =
        annotation.computeConstantValue()?.type?.element;

    if (!annotation.element!.library!.isJuggerLibrary) {
      continue;
    }

    if (valueElement == null) {
      throw UnexpectedJuggerError(
        buildUnexpectedErrorMessage(
          message: 'value if annotation [$annotation] is null',
        ),
      );
    } else {
      final bool isJuggerLibrary = valueElement.library!.isJuggerLibrary;

      if (isJuggerLibrary && valueElement.name == 'Component') {
        final List<ClassElement> modules = getClassListFromField(
          annotation,
          'modules',
        );

        final List<ClassElement> dependencies = getClassListFromField(
          annotation,
          'dependencies',
        );

        check(
          !dependencies.contains(moduleClass),
          () => buildErrorMessage(
            error: JuggerErrorId.component_depend_himself,
            message:
                'A component ${moduleClass.name} cannot depend on himself.',
          ),
        );

        final List<ModuleAnnotation> modulesAnnotations =
            modules.map((ClassElement moduleDep) {
          return ModuleExtractor().getModuleAnnotationOfModuleClass(moduleDep);
        }).toList();

        final List<ModuleAnnotation> allModules =
            modulesAnnotations.expand((ModuleAnnotation module) {
          //check repeated annotation from includes field
          checkUniqueClasses(
            module.includes
                .map((ModuleAnnotation annotation) => annotation.moduleElement),
          );
          return List<ModuleAnnotation>.from(module.includes)..add(module);
        }).toList();

        // region : check repeated annotation from modules field
        final Map<InterfaceType, List<ModuleAnnotation>> groupedAnnotations =
            modulesAnnotations.groupListsBy(
          (ModuleAnnotation annotation) => annotation.moduleElement.thisType,
        );
        for (final List<ModuleAnnotation> group in groupedAnnotations.values) {
          check(
            group.length == 1,
            () => buildErrorMessage(
              error: JuggerErrorId.repeated_modules,
              message:
                  'Repeated modules [${group.first.moduleElement.name}] not allowed.',
            ),
          );
        }
        // endregion

        annotations.add(
          ComponentAnnotation(
            modules: allModules.toList(),
            dependencies: dependencies.map((ClassElement c) {
              check(
                getComponentAnnotation(c) != null,
                () => buildErrorMessage(
                  error: JuggerErrorId.invalid_component_dependency,
                  message:
                      'Dependency ${c.name} is not allowed, only other components are allowed.',
                ),
              );
              return DependencyAnnotation(element: c);
            }).toList(),
          ),
        );
      } else if (valueElement.name == provides.runtimeType.toString()) {
        annotations.add(const ProvideAnnotation());
      } else if (valueElement.name == inject.runtimeType.toString()) {
        annotations.add(const InjectAnnotation());
      } else if (valueElement.name == module.runtimeType.toString()) {
        annotations.add(
          ModuleExtractor().getModuleAnnotationOfModuleClass(moduleClass),
        );
      } else if (valueElement.name == singleton.runtimeType.toString()) {
        annotations.add(const SingletonAnnotation());
      } else if (valueElement.name == binds.runtimeType.toString()) {
        annotations.add(const BindAnnotation());
      } else if (valueElement.name == componentBuilder.runtimeType.toString()) {
        if (valueElement is! ClassElement) {
          throw UnexpectedJuggerError(
            buildUnexpectedErrorMessage(
              message: 'element[$valueElement] is not ClassElement',
            ),
          );
        }
        annotations.add(ComponentBuilderAnnotation(valueElement));
      } else if (valueElement.name == nonLazy.runtimeType.toString()) {
        annotations.add(const NonLazyAnnotation());
      } else if (valueElement.name == disposable.runtimeType.toString()) {
        final int enumIndex = annotation
            .computeConstantValue()!
            .getField('strategy')!
            .getField('index')!
            .toIntValue()!;
        annotations
            .add(DisposableAnnotation(DisposalStrategy.values[enumIndex]));
      } else if (valueElement.name == disposalHandler.runtimeType.toString()) {
        annotations.add(const DisposalHandlerAnnotation());
      }
    }
  }
  return annotations;
}

Tag _getTag(ElementAnnotation annotation, ClassElement annotationClassElement) {
  if (annotationClassElement.name == 'Named') {
    final String? stringName =
        annotation.computeConstantValue()!.getField('name')!.toStringValue();
    checkUnexpected(
      stringName != null,
      () => buildUnexpectedErrorMessage(
        message: 'Unable get name of Named',
      ),
    );
    final String id = stringName!;
    return Tag(uniqueId: id, originalId: id);
  } else {
    final String originalId = annotationClassElement.name;
    final String uniqueId =
        '${annotationClassElement.library.source.shortName}:$originalId}';
    return Tag(uniqueId: uniqueId, originalId: originalId);
  }
}

void checkUniqueClasses(Iterable<ClassElement> classes) {
  final Map<InterfaceType, List<ClassElement>> groupedAnnotations =
      classes.groupListsBy((ClassElement annotation) => annotation.thisType);
  for (final List<ClassElement> group in groupedAnnotations.values) {
    check(
      group.length == 1,
      () => buildErrorMessage(
        error: JuggerErrorId.repeated_modules,
        message: 'Repeated modules [${group.first.name}] not allowed.',
      ),
    );
  }
}

List<ClassElement> getClassListFromField(
  ElementAnnotation annotation,
  String name,
) {
  final List<ClassElement>? result = annotation
      .computeConstantValue()
      ?.getField(name)
      ?.toListValue()
      ?.cast<DartObject>()
      // ignore: avoid_as
      .map((DartObject o) => o.toTypeValue()!.element! as ClassElement)
      .toList();
  checkUnexpected(
    result != null,
    () => buildUnexpectedErrorMessage(
      message: 'unable get $name from annotation',
    ),
  );
  return result!;
}

String uncapitalize(String name) {
  return name[0].toLowerCase() + name.substring(1);
}

String createElementPath(Element element) {
  return 'package:${element.source!.uri.path}'.replaceFirst('/lib', '');
}

bool isCore(Element element) {
  return element.librarySource!.fullName.startsWith('dart:');
}

bool isFlutterCore(Element element) {
  return element.librarySource!.fullName.startsWith('/flutter');
}

String createClassNameWithPath(ClassElement element) {
  return '${element.name} ${element.library.identifier}';
}

// ignore: avoid_positional_boolean_parameters
void check(bool condition, String Function() message) {
  if (!condition) {
    throw JuggerError(message.call());
  }
}

// ignore: avoid_positional_boolean_parameters
void checkUnexpected(bool condition, String Function() message) {
  if (!condition) {
    throw UnexpectedJuggerError(message.call());
  }
}

extension ElementExt on Element {
  ModuleAnnotation? getModuleAnnotation() {
    final Annotation? annotation = getAnnotations(this)
        .firstWhereOrNull((Annotation a) => a is ModuleAnnotation);
    return annotation is ModuleAnnotation ? annotation : null;
  }

  bool hasAnnotatedAsModule() {
    final Element element = this;
    if (element is ClassElement) {
      final List<ElementAnnotation> resolvedMetadata = element.metadata;
      final ElementAnnotation? moduleAnnotation = resolvedMetadata.firstOrNull;
      final Element? valueElement =
          moduleAnnotation?.computeConstantValue()?.type?.element;

      return valueElement?.name == module.runtimeType.toString();
    }
    return false;
  }

  bool hasAnnotatedAsInject() =>
      getAnnotations(this).any((Annotation a) => a is InjectAnnotation);

  bool hasAnnotatedAsSingleton() =>
      getAnnotations(this).any((Annotation a) => a is SingletonAnnotation);

  Tag? getQualifierTag() => getQualifierAnnotation(this)?.tag;

  String toNameWithPath() => '$name ${library?.identifier}';
}

extension ElementAnnotationExt on List<ElementAnnotation> {
  bool isQualifier() => any(
        (ElementAnnotation a) =>
            a.element!.library!.isJuggerLibrary &&
            a.element!.name == 'qualifier',
      );
}
