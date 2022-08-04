import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:quiver/core.dart';

import '../../errors_glossary.dart';
import '../../jugger_error.dart';
import '../../utils/dart_type_ext.dart';
import '../../utils/utils.dart';
import '../component_context.dart';
import '../tag.dart';
import '../wrappers.dart';
import 'multibindings_group.dart';

class MultibindingsManager {
  MultibindingsManager(this._context);

  final ComponentContext _context;

  /// All object sources that can only be used in multibindings
  late final Set<ProviderSource> _multibindingsSources =
      HashSet<ProviderSource>(
    equals: _providesSourceEquals,
    hashCode: (ProviderSource p) {
      final MultibindingsElementProvider? source =
          p as MultibindingsElementProvider?;

      if (source == null) {
        throw UnexpectedJuggerError(
          'Expected MultibindingsElementProvider, but was ${p.runtimeType}',
        );
      }
      return source.element.hashCode;
    },
  );

  void handleSource(ProviderSource source) {
    checkUnexpected(
      source is MultibindingsElementProvider,
      () => 'Expected SourceElementProvider, but was ${source.runtimeType}',
    );

    check(_multibindingsSources.add(source), () {
      final List<ProviderSource> sources = <ProviderSource>[
        _multibindingsSources
            .firstWhere((ProviderSource s) => _providesSourceEquals(s, source)),
        source
      ];

      final String places = sources
          .map((ProviderSource source) => source.sourceString)
          .join(', ');
      final String message = '${source.type} provided multiple times: $places';
      return buildErrorMessage(
        error: JuggerErrorId.multiple_providers_for_type,
        message: message,
      );
    });
  }

  List<MultibindingsGroup> getBindingsInfo() {
    final Map<_MultibindsGroup, Set<ProviderSource>> groups =
        _multibindingsSources.groupSetsBy((ProviderSource source) {
      final MultibindingsElementProvider provider =
          source as MultibindingsElementProvider;

      final MultibindingsGroupAnnotation? annotation =
          provider.element.getMultibindingsGroupAnnotationOrNull();

      if (annotation == null) {
        throw UnexpectedJuggerError('MultibindingsGroupAnnotation is null');
      }

      final _MultibindsGroup multibindsGroup;

      if (annotation is IntoSetAnnotation) {
        multibindsGroup = _MultibindsGroup.set(
          valueType: source.type,
          tag: source.tag,
        );
      } else if (annotation is IntoMapAnnotation) {
        final MultibindingsKeyAnnotation<Object?> key =
            provider.element.getSingleMultibindsKeyAnnotation();

        multibindsGroup = _MultibindsGroup.map(
          valueType: source.type,
          keyType: key.type,
          tag: source.tag,
        );
      } else {
        throw UnexpectedJuggerError(
          'Unknown multibindings annotation $annotation',
        );
      }

      return multibindsGroup;
    });

    return groups.keys.map((_MultibindsGroup key) {
      final List<ProviderSource> providers =
          groups[key]!.toList(growable: false);
      check(providers.isNotEmpty, () => 'providers is empty');

      if (key is _SetMultibindsGroup) {
        return _createGroupForSet(key, providers);
      } else if (key is _MapMultibindsGroup) {
        return _createGroupForMap(key, providers);
      }

      throw UnexpectedJuggerError('Unknown group $key');
    }).toList(growable: false);
  }

  MultibindingsGroup _createGroupForMap(
    _MapMultibindsGroup key,
    List<ProviderSource> providers,
  ) {
    final DartType keyType = key.keyType;
    final DartType valueType = key.valueType;
    final Tag? tag = key.tag;

    final String multibindingTypeString =
        "Map<${keyType.getName()}, ${valueType.getName()}>";

    final GraphObject? graphObject =
        _context.graphObjects.firstWhereOrNull((GraphObject element) {
      return element.tag == tag &&
          element.type.getName() == multibindingTypeString;
    });
    check(
      graphObject != null,
      () => buildErrorMessage(
        error: JuggerErrorId.unused_multibinding,
        message:
            'Multibindings $multibindingTypeString is declared, but not used.',
      ),
    );

    _checkDuplicateKeys(providers);

    return MultibindingsGroup(
      providers: providers,
      graphObject: graphObject!,
      tag: tag,
      annotations: <Annotation>[if (tag != null) QualifierAnnotation(tag: tag)],
    );
  }

  MultibindingsGroup _createGroupForSet(
    _SetMultibindsGroup key,
    List<ProviderSource> providers,
  ) {
    final DartType valueType = key.valueType;
    final Tag? tag = key.tag;

    final String multibindingTypeString = "Set<${valueType.getName()}>";

    final GraphObject? graphObject =
        _context.graphObjects.firstWhereOrNull((GraphObject element) {
      return element.tag == tag &&
          element.type.getName() == multibindingTypeString;
    });
    check(
      graphObject != null,
      () => buildErrorMessage(
        error: JuggerErrorId.unused_multibinding,
        message:
            'Multibindings $multibindingTypeString is declared, but not used.',
      ),
    );
    return MultibindingsGroup(
      providers: providers,
      graphObject: graphObject!,
      tag: tag,
      annotations: <Annotation>[if (tag != null) QualifierAnnotation(tag: tag)],
    );
  }

  /// When forming a [Map], duplicate keys are not allowed.
  void _checkDuplicateKeys(List<ProviderSource> providers) {
    final Map<Object?, Set<ProviderSource>> groupedKeys = providers.groupSetsBy(
      (ProviderSource element) => (element as MultibindingsElementProvider)
          .element
          .getSingleMultibindsKeyAnnotation()
          .key,
    );

    check(
      groupedKeys.values.every((Set<ProviderSource> keys) => keys.length == 1),
      () {
        final Iterable<String> duplicates = groupedKeys.keys
            .where((Object? key) {
              return groupedKeys[key]!.length > 1;
            })
            .map((Object? key) => groupedKeys[key]!)
            .expand(
              (Set<ProviderSource> providers) => providers.map(
                (ProviderSource provider) => provider.sourceString,
              ),
            )
            .sortedBy((String s) => s);

        return buildErrorMessage(
          error: JuggerErrorId.multibindings_duplicates_keys,
          message: 'Multibindings not allowed with duplicates keys:\n'
              '${duplicates.join('\n')}',
        );
      },
    );
  }

  bool _providesSourceEquals(ProviderSource p1, ProviderSource p2) {
    final MultibindingsElementProvider? source1 =
        p1 as MultibindingsElementProvider?;
    final MultibindingsElementProvider? source2 =
        p2 as MultibindingsElementProvider?;
    if (source1 == null || source2 == null) {
      throw UnexpectedJuggerError('Expected MultibindingsElementProvider.');
    }
    return source1.element == source2.element;
  }
}

abstract class _MultibindsGroup {
  const factory _MultibindsGroup.set({
    required DartType valueType,
    required Tag? tag,
  }) = _SetMultibindsGroup;

  const factory _MultibindsGroup.map({
    required DartType keyType,
    required DartType valueType,
    required Tag? tag,
  }) = _MapMultibindsGroup;
}

class _SetMultibindsGroup implements _MultibindsGroup {
  const _SetMultibindsGroup({required this.valueType, this.tag});

  final DartType valueType;
  final Tag? tag;

  @override
  bool operator ==(Object o) =>
      o is _SetMultibindsGroup && valueType == o.valueType && tag == o.tag;

  @override
  int get hashCode => hash2(valueType.hashCode, tag.hashCode);
}

class _MapMultibindsGroup implements _MultibindsGroup {
  const _MapMultibindsGroup({
    required this.keyType,
    required this.valueType,
    this.tag,
  });

  final DartType keyType;
  final DartType valueType;
  final Tag? tag;

  @override
  bool operator ==(Object o) =>
      o is _MapMultibindsGroup &&
      keyType == o.keyType &&
      valueType == o.valueType &&
      tag == o.tag;

  @override
  int get hashCode => hash3(keyType.hashCode, valueType.hashCode, tag.hashCode);
}
