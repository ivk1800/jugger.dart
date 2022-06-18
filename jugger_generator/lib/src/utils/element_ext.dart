import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';

import '../errors_glossary.dart';
import '../generator/wrappers.dart';
import '../jugger_error.dart';
import 'utils.dart';

extension ElementExt on Element {
  /// The method tries to get the type from the supported element type,
  /// otherwise it throws an error.
  DartType tryGetType() {
    final Element element = this;
    if (element is ClassElement) {
      return element.thisType;
    } else if (element is ParameterElement) {
      return element.type;
    }

    throw UnexpectedJuggerError(
      buildUnexpectedErrorMessage(
        message: 'Unable get type of [$element]',
      ),
    );
  }

  T castToOrThrow<T extends Element>() {
    final Element element = this;
    if (element is T) {
      return element;
    }
    throw UnexpectedJuggerError(
      buildUnexpectedErrorMessage(
        message: 'Expected type $T, but was $element',
      ),
    );
  }

  DisposalHandlerAnnotation? getDisposalHandlerAnnotation() {
    final Annotation? annotation = getAnnotations(this)
        .firstWhereOrNull((Annotation a) => a is DisposalHandlerAnnotation);
    return annotation is DisposalHandlerAnnotation ? annotation : null;
  }
}
