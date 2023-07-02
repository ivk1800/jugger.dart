import 'package:collection/collection.dart';
import 'package:quiver/core.dart';

import '../../utils/comparable_ext.dart';
import '../tag.dart';

/// Information about multibindings.
class MultibindingsInfo implements Comparable<MultibindingsInfo> {
  MultibindingsInfo({
    required this.tag,
    required this.methodPath,
  });

  /// Group can have a qualifier.
  final Tag? tag;

  /// [methodPath] is an identifier because can be several providers in one
  /// module that return the same type.
  final String methodPath;

  @override
  bool operator ==(Object o) =>
      o is MultibindingsInfo && tag == o.tag && methodPath == o.methodPath;

  @override
  int get hashCode => hash2(tag.hashCode, methodPath);

  @override
  int compareTo(MultibindingsInfo other) {
    return (MultibindingsInfo a, MultibindingsInfo b) {
      return compareNullable<Tag>(a.tag, b.tag);
    }
        .then(
          (MultibindingsInfo a, MultibindingsInfo b) =>
              a.methodPath.compareTo(b.methodPath),
        )
        .call(this, other);
  }
}
