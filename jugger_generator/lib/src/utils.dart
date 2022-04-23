import 'dart:convert';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:jugger/jugger.dart';
import 'package:jugger_generator/src/jugger_error.dart';

import 'classes.dart';
import 'library_ext.dart';
import 'messages.dart';
import 'visitors.dart';

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
  check2(
    qualifierAnnotation.length <= 1,
    () => multipleQualifiersNotAllowed(element),
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
          annotationElement.variable.type.element as ClassElement;
      final bool isQualifier = annotationClassElement.metadata.isQualifier();

      if (isQualifier) {
        annotations.add(
          QualifierAnnotation(
            tag: '${annotationClassElement.name}',
          ),
        );
      }
    } else if (annotationElement is ConstructorElement) {
      final ClassElement annotationClassElement =
          annotationElement.enclosingElement;
      final bool isQualifier = annotationClassElement.metadata.isQualifier();
      if (isQualifier) {
        annotations.add(
          QualifierAnnotation(
            tag: annotationClassElement.name == 'Named'
                ? '${annotation.computeConstantValue()!.getField('name')!.toStringValue()!}'
                : '${annotationClassElement.name}',
          ),
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
      throw JuggerError('value if annotation [$annotation] is null');
    } else {
      final bool isJuggerLibrary = valueElement.library!.isJuggerLibrary;

      if (isJuggerLibrary && valueElement.name == 'Component') {
        final List<ClassElement> modules = annotation
            .computeConstantValue()!
            .getField('modules')!
            .toListValue()!
            .cast<DartObject>()
            // ignore: avoid_as
            .map((DartObject o) => o.toTypeValue()!.element as ClassElement)
            .toList();

        final List<ClassElement> dependencies = annotation
            .computeConstantValue()!
            .getField('dependencies')!
            .toListValue()!
            .cast<DartObject>()
            // ignore: avoid_as
            .map((DartObject o) => o.toTypeValue()!.element as ClassElement)
            .toList();

        final List<ModuleAnnotation> modulesAnnotations =
            modules.map((ClassElement moduleDep) {
          return moduleDep.getModuleAnnotationOfModuleClass();
        }).toList();

        final Map<InterfaceType, List<ModuleAnnotation>> groupedAnnotations =
            modulesAnnotations.groupListsBy((ModuleAnnotation annotation) =>
                annotation.moduleElement.thisType);
        for (List<ModuleAnnotation> group in groupedAnnotations.values) {
          check2(
            group.length == 1,
            () => repeatedModules(group.first.moduleElement.thisType),
          );
        }

        annotations.add(ComponentAnnotation(
            element: valueElement,
            modules: modulesAnnotations,
            dependencies: dependencies.map((ClassElement c) {
              check2(c.isAbstract, () => dependencyMustBeAbstract(c.thisType));
              return DependencyAnnotation(element: c);
            }).toList()));
      } else if (valueElement.name == provides.runtimeType.toString()) {
        annotations.add(ProvideAnnotation());
      } else if (valueElement.name == inject.runtimeType.toString()) {
        annotations.add(InjectAnnotation());
      } else if (valueElement.name == module.runtimeType.toString()) {
        annotations.add(moduleClass.getModuleAnnotationOfModuleClass());
      } else if (valueElement.name == singleton.runtimeType.toString()) {
        annotations.add(SingletonAnnotation());
      } else if (valueElement.name == binds.runtimeType.toString()) {
        annotations.add(BindAnnotation());
      } else if (valueElement.name == componentBuilder.runtimeType.toString()) {
        if (!(valueElement is ClassElement)) {
          throw JuggerError('element[$valueElement] is not ClassElement');
        }
        annotations.add(ComponentBuilderAnnotation(valueElement));
      } else if (valueElement.name == nonLazy.runtimeType.toString()) {
        annotations.add(NonLazyAnnotation());
      }
    }
  }
  return annotations;
}

String uncapitalize(String name) {
  return name[0].toLowerCase() + name.substring(1);
}

String createElementPath(Element element) {
  if (isCore(element)) {
    return 'dart:core';
  }

  return 'package:${element.source!.uri.path}'.replaceFirst('/lib', '');
}

bool isCore(Element element) {
  return element.librarySource!.fullName.startsWith('dart:core');
}

bool isFlutterCore(Element element) {
  return element.librarySource!.fullName.startsWith('/flutter');
}

String createClassNameWithPath(ClassElement element) {
  return '${element.name}] ${element.library.identifier}';
}

void check(bool condition, String message) {
  if (!condition) {
    throw JuggerError(message);
  }
}

void check2(bool condition, String Function() message) {
  if (!condition) {
    throw JuggerError(message.call());
  }
}

extension DartTypeExt on DartType {
  String getName() {
    return getDisplayString(withNullability: true);
  }

  bool hasInjectedConstructor() {
    checkUnsupportedType();

    final InjectedConstructorsVisitor visitor = InjectedConstructorsVisitor();
    element!.visitChildren(visitor);

    check2(
      visitor.injectedConstructors.length < 2,
      () => 'too many injected constructors of [${getName()}]',
    );
    return visitor.injectedConstructors.length == 1;
  }

  void checkUnsupportedType() {
    check2(this is InterfaceType, () => 'type [$this] not supported');

    check2(
      nullabilitySuffix == NullabilitySuffix.none,
      () => typeNotSupported(this),
    );
  }
}

extension ElementExt on Element {
  ModuleAnnotation? getModuleAnnotation() {
    final Annotation? annotation = getAnnotations(this)
        .firstWhereOrNull((Annotation a) => a is ModuleAnnotation);
    return annotation is ModuleAnnotation ? annotation : null;
  }

  bool hasAnnotatedAsModule() => getModuleAnnotation() != null;

  bool hasAnnotatedAsSingleton() =>
      getAnnotations(this).any((Annotation a) => a is SingletonAnnotation);

  ModuleAnnotation getModuleAnnotationOfModuleClass() {
    final Element moduleClass = this;

    if (!(moduleClass is ClassElement)) {
      throw JuggerError('element[$moduleClass] is not ClassElement');
    }
    check2(moduleClass.isAbstract, () => moduleMustBeAbstract(moduleClass));
    check2(moduleClass.isPublic, () => publicModule(moduleClass));
    return ModuleAnnotation(moduleElement: moduleClass);
  }

  String? getQualifierTag() => getQualifierAnnotation(this)?.tag;

  String toNameWithPath() => '$name] ${library?.identifier}';
}

extension ElementAnnotationExt on List<ElementAnnotation> {
  bool isQualifier() => any(
        (ElementAnnotation a) =>
            a.element!.library!.isJuggerLibrary &&
            a.element!.name == 'qualifier',
      );
}
