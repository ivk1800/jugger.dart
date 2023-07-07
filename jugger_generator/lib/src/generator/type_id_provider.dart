import 'package:analyzer/dart/element/type.dart';

import 'multibindings/multibindings_info.dart';
import 'tag.dart';

/// Returns a unique type identifier within a single component
/// Parent and child component can have types with the same id.
abstract class TypeIdProvider {
  int getIdOf({
    required DartType type,
    Tag? tag,
    MultibindingsInfo? multibindingsInfo,
  });
}
