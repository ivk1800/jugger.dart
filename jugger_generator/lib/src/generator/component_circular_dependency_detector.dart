import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';

import '../errors_glossary.dart';
import '../jugger_error.dart';
import '../utils/utils.dart';

class ComponentCircularDependencyDetector {
  final Queue<ClassElement> _queue = Queue<ClassElement>();

  void beginHandleComponent(ClassElement componentClass) {
    if (_queue.contains(componentClass)) {
      _queue.addFirst(componentClass);
      final String chain = _queue
          .toList()
          .reversed
          .map((ClassElement component) => component.name)
          .join('->');
      throw JuggerError(
        buildErrorMessage(
          error: JuggerErrorId.circular_dependency,
          message: 'Found circular dependency! $chain',
        ),
      );
    }

    _queue.addFirst(componentClass);
  }

  void endHandleComponent(ClassElement componentClass) {
    final ClassElement? first = _queue.firstOrNull;
    checkUnexpected(
      first == componentClass,
      () {
        return 'Expected $componentClass, but was $first';
      },
    );
    _queue.removeFirst();
  }
}
