import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:jugger/jugger.dart';

import 'classes.dart';

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

DisposableAnnotation? getDisposableAnnotation(Element element) {
  final Annotation? annotation = getAnnotations(element)
      .firstWhereOrNull((Annotation a) => a is DisposableAnnotation);
  return annotation is DisposableAnnotation ? annotation : null;
}

ProvideAnnotation? getProvideAnnotation(Element element) {
  final Annotation? annotation = getAnnotations(element)
      .firstWhereOrNull((Annotation a) => a is ProvideAnnotation);
  return annotation is ProvideAnnotation ? annotation : null;
}

NamedAnnotation? getNamedAnnotation(Element element) {
  final Annotation? annotation = getAnnotations(element)
      .firstWhereOrNull((Annotation a) => a is NamedAnnotation);
  return annotation is NamedAnnotation ? annotation : null;
}

List<Annotation> getAnnotations(Element moduleClass) {
  final List<Annotation> annotations = <Annotation>[];

  final List<ElementAnnotation> resolvedMetadata = moduleClass.metadata;

  for (int i = 0; i < resolvedMetadata.length; i++) {
    final ElementAnnotation annotation = resolvedMetadata[i];
    final Element? valueElement =
        annotation.computeConstantValue()?.type?.element;

    if (valueElement == null) {
      // ignore: flutter_style_todos
      //TODO
    } else {
      if (valueElement.name == 'Component') {
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

        annotations.add(ComponentAnnotation(
            element: valueElement,
            modules: modules.map((ClassElement moduleDep) {
              return moduleDep.getModuleAnnotationOfModuleClass();
            }).toList(),
            dependencies: dependencies.map((ClassElement c) {
              if (!c.isAbstract) {
                throw StateError(
                  'dependency must be abstract [${c.thisType.getName()}]',
                );
              }
              return DependencyAnnotation(element: c);
            }).toList()));
      } else if (valueElement.name == provide.runtimeType.toString()) {
        annotations.add(ProvideAnnotation());
      } else if (valueElement.name == inject.runtimeType.toString()) {
        annotations.add(InjectAnnotation());
      } else if (valueElement.name == module.runtimeType.toString()) {
        annotations.add(moduleClass.getModuleAnnotationOfModuleClass());
      } else if (valueElement.name == singleton.runtimeType.toString()) {
        annotations.add(SingletonAnnotation());
      } else if (valueElement.name == bind.runtimeType.toString()) {
        annotations.add(BindAnnotation());
      } else if (valueElement.name == 'Disposable') {
        annotations.add(DisposableAnnotation());
      } else if (valueElement.name == componentBuilder.runtimeType.toString()) {
        if (!(valueElement is ClassElement)) {
          throw StateError('element[$valueElement] is not ClassElement');
        }
        annotations.add(ComponentBuilderAnnotation(valueElement));
      } else if (valueElement.name == (Named).runtimeType.toString()) {
        if (!(valueElement is ClassElement)) {
          throw StateError('element[$valueElement] is not ClassElement');
        }
        annotations.add(NamedAnnotation(
            element: valueElement,
            name: annotation
                .computeConstantValue()!
                .getField('name')!
                .toStringValue()!));
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

void check(bool condition, String message) {
  if (!condition) {
    throw StateError(message);
  }
}

extension DartTypeExt on DartType {
  String getName() {
    return getDisplayString(withNullability: true);
  }
}

extension ElementExt on Element {
  ModuleAnnotation? getModuleAnnotation() {
    final Annotation? annotation = getAnnotations(this)
        .firstWhereOrNull((Annotation a) => a is ModuleAnnotation);
    return annotation is ModuleAnnotation ? annotation : null;
  }

  bool hasAnnotatedAsModule() => getModuleAnnotation() != null;

  ModuleAnnotation getModuleAnnotationOfModuleClass() {
    final Element moduleClass = this;

    if (!(moduleClass is ClassElement)) {
      throw StateError('element[$moduleClass] is not ClassElement');
    }
    if (!moduleClass.isAbstract) {
      throw StateError(
        'module must be abstract [${moduleClass.thisType.getName()}] ${moduleClass.library.identifier}',
      );
    }
    return ModuleAnnotation(moduleElement: moduleClass);
  }
}
