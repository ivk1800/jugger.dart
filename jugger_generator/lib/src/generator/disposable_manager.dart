import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:jugger/jugger.dart' as j;

import '../errors_glossary.dart';
import '../utils/dart_type_ext.dart';
import '../utils/source_ext.dart';
import '../utils/utils.dart';
import 'component_context.dart';
import 'tag.dart';
import 'visitors.dart';
import 'wrappers.dart';

class DisposablesManager {
  DisposablesManager(ComponentContext context) {
    disposalHandlerMethods = context.component.disposalHandlerMethods;
    allDisposable = _findDisposableGraphObjects(context);

    for (final DisposalHandlerMethod handler in disposalHandlerMethods) {
      final DisposableInfo? disposable = allDisposable.firstWhereOrNull(
        (DisposableInfo info) => info.type == handler.disposableType,
      );
      check(
        disposable != null,
        () => buildErrorMessage(
          error: JuggerErrorId.unused_disposal_handler,
          message:
              'Found unused disposal handler ${handler.element.enclosingElement3.name}.${handler.element.name}.',
        ),
      );
      check(
        disposable!.disposeHandler is DelegateDisposeHandler,
        () => buildErrorMessage(
          error: JuggerErrorId.redundant_disposal_handler,
          message:
              '${disposable.type.getName()} marked as auto disposable, but declared handler ${handler.element.enclosingElement3.name}.${handler.element.name}.',
        ),
      );
    }
    disposableArguments = allDisposable
        .where((DisposableInfo info) => info.source == Source.argument)
        // Sort so that the sequence is preserved with each code generation (for
        // test stability)
        .sorted((DisposableInfo a, DisposableInfo b) {
      return '${a.type.getName()}${a.tag}'
          .compareTo('${b.type.getName()}${b.tag}');
    }).toList(growable: false);
    otherDisposable = allDisposable
        .where(
      (DisposableInfo info) => info.source == Source.other,
    )
        // Sort so that the sequence is preserved with each code generation (for
        // test stability)
        .sorted((DisposableInfo a, DisposableInfo b) {
      return '${a.type.getName()}${a.tag}'
          .compareTo('${b.type.getName()}${b.tag}');
    }).toList(growable: false);
  }

  /// All graph objects that need to be disposed.
  late final List<DisposableInfo> allDisposable;

  /// All graph objects passed from the component arguments that need to be
  /// disposed.
  late final List<DisposableInfo> disposableArguments;

  /// All other objects for disposal, except arguments.
  late final List<DisposableInfo> otherDisposable;

  /// All disposal methods of object taken from modules.
  late final List<DisposalHandlerMethod> disposalHandlerMethods;

  /// Returns true if the component contains objects that need to be disposed.
  bool hasDisposables() =>
      disposableArguments.isNotEmpty || otherDisposable.isNotEmpty;

  /// Find information about the disposing object by the given type and tag.
  DisposableInfo? findDisposableInfo(DartType type, Tag? tag) {
    return allDisposable.firstWhereOrNull(
      (DisposableInfo disposable) =>
          disposable.type == type && disposable.tag == tag,
    );
  }

  /// Find all objects for disposing. Filters objects from parent.
  List<DisposableInfo> _findDisposableGraphObjects(ComponentContext context) {
    final List<GraphObject> graphObjects = context.graphObjects;

    final List<DisposableInfo> sources = <DisposableInfo>[];

    for (final GraphObject graphObject in graphObjects) {
      final ProviderSource source = context.findProvider(
        graphObject.type,
        graphObject.tag,
        graphObject.multibindingsInfo,
      );

      if (source is ParentComponentSource) {
        // disposable object from parent - no need to do anything with it
        continue;
      }

      if (source is InjectedConstructorSource) {
        final DisposableAnnotation? disposableAnnotation =
            graphObject.type.getDisposableAnnotation();

        if (disposableAnnotation != null) {
          check(
            graphObject.type.isScoped(),
            () => buildErrorMessage(
              error: JuggerErrorId.disposable_not_scoped,
              message:
                  '${graphObject.type.getName()} marked as disposable, but not scoped.',
            ),
          );
          sources.add(
            DisposableInfo._(
              type: graphObject.type,
              tag: null,
              source: Source.other,
              disposeHandler: _getDisposeHandler(
                disposableAnnotation,
                graphObject.type,
                null,
              ),
            ),
          );
          continue;
        }
        continue;
      }

      final DisposableAnnotation? disposableAnnotation =
          source.annotations.firstWhereOrNull((Annotation annotation) {
        return annotation is DisposableAnnotation;
      }) as DisposableAnnotation?;

      if (disposableAnnotation == null) {
        continue;
      }

      if (source is ArgumentSource) {
        sources.add(
          DisposableInfo._(
            type: source.type,
            tag: source.tag,
            source: _getSource(source),
            disposeHandler: _getDisposeHandler(
              disposableAnnotation,
              source.type,
              source.tag,
            ),
          ),
        );
        continue;
      }

      final bool isBinds = source.annotations.any((Annotation annotation) {
        return annotation is BindAnnotation;
      });
      check(
        !isBinds,
        () => buildErrorMessage(
          error: JuggerErrorId.disposable_not_supported,
          message:
              'Disposable type ${source.type.getName()} not supported with binds.',
        ),
      );

      check(
        source.isScoped,
        () => buildErrorMessage(
          error: JuggerErrorId.disposable_not_scoped,
          message:
              '${graphObject.type.getName()} marked as disposable, but not scoped.',
        ),
      );
      sources.add(
        DisposableInfo._(
          type: source.type,
          tag: source.tag,
          source: _getSource(source),
          disposeHandler: _getDisposeHandler(
            disposableAnnotation,
            source.type,
            source.tag,
          ),
        ),
      );
      continue;
    }
    return sources;
  }

  /// Map provider to internal source for convenience.
  Source _getSource(ProviderSource source) {
    if (source is ArgumentSource) {
      return Source.argument;
    }

    return Source.other;
  }

  DisposeHandler _getDisposeHandler(
    DisposableAnnotation disposableAnnotation,
    DartType type,
    Tag? tag,
  ) {
    switch (disposableAnnotation.strategy) {
      case j.DisposalStrategy.auto:
        check(
          type.element2!.getMethods().any((MethodElement mrthod) {
            final String type = mrthod.returnType.getName();
            return mrthod.name == 'dispose' &&
                (type == 'Future<void>' || type == 'void');
          }),
          () => buildErrorMessage(
            error: JuggerErrorId.missing_dispose_method,
            message:
                '${type.getName()} marked as auto disposable, but not found properly dispose method.',
          ),
        );
        return const SelfDisposeHandler();
      case j.DisposalStrategy.delegated:
        final DisposalHandlerMethod? method =
            disposalHandlerMethods.firstWhereOrNull(
          (DisposalHandlerMethod handler) =>
              handler.disposableType == type && handler.tag == tag,
        );

        check(
          method != null,
          () => buildErrorMessage(
            error: JuggerErrorId.missing_dispose_method,
            message: 'Not found disposer for $type.',
          ),
        );
        return DelegateDisposeHandler(method: method!.element);
    }
  }
}

class DisposableInfo {
  DisposableInfo._({
    required this.type,
    required this.tag,
    required this.source,
    required this.disposeHandler,
  });

  /// Type of disposed object.
  final DartType type;
  final Tag? tag;

  /// From where the object is provided. Depending on the type of object, it
  /// can be disposed of in a special way.
  final Source source;
  final DisposeHandler disposeHandler;
}

/// From where the object is provided.
enum Source {
  /// arguments of component.
  argument,

  /// All other providers.
  other,
}

abstract class DisposeHandler {}

class SelfDisposeHandler implements DisposeHandler {
  const SelfDisposeHandler();
}

class DelegateDisposeHandler implements DisposeHandler {
  DelegateDisposeHandler({required this.method});

  final MethodElement method;
}
