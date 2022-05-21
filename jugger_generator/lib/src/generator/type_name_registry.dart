import 'package:analyzer/dart/element/type.dart';

import '../utils/dart_type_ext.dart';

/// The primary purpose is to generate a unique name for types that have the
/// same name but are from different files.
///
/// Should only be used in single BuildStep.
class TypeNameGenerator {
  final Map<String, Map<DartType, String>> _names =
      <String, Map<DartType, String>>{};

  /// Generates name for type. If the type has invalid characters, such as
  /// brackets, they will be stripped.
  String generate(DartType type) {
    final String typeName = type
        .getName()
        .replaceAll('<', '_')
        .replaceAll('>', '_')
        .replaceAll(' ', '')
        .replaceAll(',', '_');

    if (!_names.containsKey(typeName)) {
      _names[typeName] = <DartType, String>{type: typeName};
      return typeName;
    } else {
      final Map<DartType, String> namesOfTypes = _names[typeName]!;
      final String? finalName = namesOfTypes[type];
      if (finalName == null) {
        final String newName = '$typeName${namesOfTypes.length}';
        namesOfTypes[type] = newName;
        return newName;
      } else {
        return finalName;
      }
    }
  }
}
