import 'package:analyzer/dart/element/element.dart';

import '../generator/wrappers.dart';

final SessionCache sessionCache = SessionCache._internal();

class SessionCache {
  SessionCache._internal();

  final Map<int, List<Annotation>> _annotationsCache =
      <int, List<Annotation>>{};

  List<Annotation> getAnnotations(
    Element element,
    List<Annotation> Function() ifAbsent,
  ) =>
      _annotationsCache.putIfAbsent(element.id, ifAbsent);
}
