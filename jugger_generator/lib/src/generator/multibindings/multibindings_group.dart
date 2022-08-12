import '../component_context.dart';
import '../wrappers.dart';

/// Multibindings group. Contains final information that can be used to
/// generate. Is it a [Set] or [Map].
class MultibindingsGroup {
  MultibindingsGroup({
    required this.providers,
    required this.annotations,
    required this.graphObject,
  });

  /// Providers that are used to form [Set] or [Map].
  final List<ProviderSource> providers;

  /// General group annotations.
  final List<Annotation> annotations;

  /// Group graph object, Set<T> or Map<K, V>.
  final GraphObject graphObject;
}
