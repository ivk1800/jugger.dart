import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../errors_glossary.dart';
import '../jugger_error.dart';

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

    throw JuggerError(
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
    throw JuggerError(
      buildUnexpectedErrorMessage(
        message: 'Expected type $T, but was $element',
      ),
    );
  }
}
