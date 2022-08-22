import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:code_builder/code_builder.dart';

import '../generator/tag.dart';
import '../jugger_error.dart';
import 'element_annotation_ext.dart';
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

    throw UnexpectedJuggerError('Unable get type of [$element]');
  }

  T castToOrThrow<T extends Element>() {
    final Element element = this;
    if (element is T) {
      return element;
    }
    throw UnexpectedJuggerError('Expected type $T, but was $element');
  }

  Tag? getQualifierTag() => getQualifierAnnotationOrNull()?.tag;

  String toNameWithPath() => '$name ${library?.identifier}';

  Reference asReference() {
    final String? n = name;
    check(n != null, () => 'Unable create Reference, name is null');
    final Source? library = librarySource;
    check(
      library != null,
      () => 'Unable create Reference, librarySource is null',
    );
    return refer(n!, library!.uri.toString());
  }
}
