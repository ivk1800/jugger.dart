import '../generator/tag.dart';
import 'utils.dart';

extension TagExt on Tag {
  /// Convert tag to unique string.
  String toAssignTag() => generateMd5(uniqueId);
}
