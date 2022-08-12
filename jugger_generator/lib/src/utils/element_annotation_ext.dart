import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:jugger/jugger.dart';

import '../errors_glossary.dart';
import '../generator/wrappers.dart';
import '../jugger_error.dart';
import 'library_ext.dart';
import 'list_ext.dart';
import 'utils.dart';

extension ElementAnnotationExt on Element {
  ComponentAnnotation? getComponentAnnotationOrNull() =>
      getAnnotationOrNull<ComponentAnnotation>();

  BindAnnotation? getBindAnnotationOrNull() =>
      getAnnotationOrNull<BindAnnotation>();

  ProvideAnnotation? getProvideAnnotationOrNull() =>
      getAnnotationOrNull<ProvideAnnotation>();

  QualifierAnnotation? getQualifierAnnotationOrNull() {
    final List<QualifierAnnotation> qualifierAnnotation =
        getAnnotations(this).whereType<QualifierAnnotation>().toList();
    check(
      qualifierAnnotation.length <= 1,
      () => buildErrorMessage(
        error: JuggerErrorId.multiple_qualifiers,
        message:
            'Multiple qualifiers of ${enclosingElement?.name}.$name not allowed.',
      ),
    );

    return qualifierAnnotation.firstInstanceOrNull<QualifierAnnotation>();
  }

  ComponentBuilderAnnotation? getComponentBuilderAnnotationOrNull() =>
      getAnnotationOrNull<ComponentBuilderAnnotation>();

  DisposalHandlerAnnotation? getDisposalHandlerAnnotationOrNull() =>
      getAnnotationOrNull<DisposalHandlerAnnotation>();

  ModuleAnnotation? getModuleAnnotation() =>
      getAnnotationOrNull<ModuleAnnotation>();

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
      getAnnotations(this).anyInstance<InjectAnnotation>();

  bool hasAnnotatedAsSingleton() =>
      getAnnotations(this).anyInstance<SingletonAnnotation>();

  List<MultibindingsGroupAnnotation> getMultibindingsAnnotations() {
    return getAnnotations(this)
        .whereType<MultibindingsGroupAnnotation>()
        .toList(growable: false);
  }

  List<MultibindingsKeyAnnotation<Object?>> getMultibindsKeyAnnotations() {
    return getAnnotations(this)
        .whereType<MultibindingsKeyAnnotation<Object?>>()
        .toList(growable: false);
  }

  MultibindingsKeyAnnotation<Object?> getSingleMultibindsKeyAnnotation() {
    check(
      this is MethodElement,
      () => buildUnexpectedErrorMessage(
        message: 'Expected MethodElement, but was $this',
      ),
    );

    final List<MultibindingsKeyAnnotation<Object?>> keys =
        getMultibindsKeyAnnotations();

    check(
      keys.isNotEmpty,
      () => buildErrorMessage(
        error: JuggerErrorId.multibindings_missing_key,
        message: 'Methods of type map must declare a map key:\n'
            '${(enclosingElement as ClassElement).name}.$name',
      ),
    );

    check(
      keys.length == 1,
      () => buildErrorMessage(
        error: JuggerErrorId.multibindings_multiple_keys,
        message: 'Methods may not have more than one map key:\n'
            '${(enclosingElement as ClassElement).name}.$name\n'
            'keys: ${keys.map((MultibindingsKeyAnnotation<Object?> annotation) => annotation.key).join(', ')}',
      ),
    );

    return keys.first;
  }

  T getAnnotation<T extends Annotation>() {
    final Annotation? annotation =
        getAnnotations(this).firstWhereOrNull((Annotation a) => a is T);
    return annotation is T
        ? annotation
        : (throw JuggerError('Annotation $T not found'));
  }

  T? getAnnotationOrNull<T extends Annotation>() {
    final Annotation? annotation =
        getAnnotations(this).firstWhereOrNull((Annotation a) => a is T);
    return annotation is T ? annotation : null;
  }
}

extension MethodElementExt on MethodElement {
  MultibindingsGroupAnnotation? getMultibindingsGroupAnnotationOrNull() {
    final List<MultibindingsGroupAnnotation> multibindingsAnnotations =
        getMultibindingsAnnotations();

    if (multibindingsAnnotations.isEmpty) {
      return null;
    }

    check(
      multibindingsAnnotations.length == 1,
      () => buildErrorMessage(
        error: JuggerErrorId.multiple_multibinding_annotation,
        message: 'Methods cannot have more than one multibinding annotation:\n'
            '${enclosingElement.name}.$name',
      ),
    );

    return multibindingsAnnotations.first;
  }
}

extension ListElementAnnotationExt on List<ElementAnnotation> {
  bool isQualifier() => any(
        (ElementAnnotation a) =>
            a.element!.library!.isJuggerLibrary &&
            a.element!.name == 'qualifier',
      );

  bool isMapKey() => any(
        (ElementAnnotation a) =>
            a.element!.library!.isJuggerLibrary && a.element!.name == 'mapKey',
      );
}
