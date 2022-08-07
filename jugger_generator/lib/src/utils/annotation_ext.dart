import 'package:collection/collection.dart';

import '../generator/wrappers.dart';
import '../jugger_error.dart';

extension AnnotationsExt on List<Annotation> {
  T getAnnotation<T extends Annotation>() {
    final Annotation? annotation = firstWhereOrNull((Annotation a) => a is T);
    return annotation is T
        ? annotation
        : (throw JuggerError('Annotation $T not found'));
  }

  T? getAnnotationOrNull<T extends Annotation>() {
    final Annotation? annotation = firstWhereOrNull((Annotation a) => a is T);
    return annotation is T ? annotation : null;
  }
}
