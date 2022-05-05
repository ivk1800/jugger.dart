const String _glossary =
    'https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_build_method';
const String missingBuildMethod = '$_glossary#missing_build_method';
const String wrongTypeOfBuildMethod = '$_glossary#wrong_type_of_build_method';
const String missingComponentDependency =
    '$_glossary#missing_component_dependency';
const String publicComponentBuilder = '$_glossary#public_component_builder';
const String componentBuilderInvalidMethodParameters =
    '$_glossary#component_builder_invalid_method_parameters';
const String componentBuilderInvalidMethodType =
    '$_glossary#component_builder_invalid_method_type';
const String wrongArgumentsOfBuildMethod =
    '$_glossary#wrong_arguments_of_build_method';
const String componentBuilderTypeProvidesMultipleTimes =
    '$_glossary#component_builder_type_provides_multiple_times';
const String componentBuilderPrivateMethod =
    '$_glossary#component_builder_private_method';

enum JuggerErrorId {
  missing_build_method,
  wrong_type_of_build_method,
  missing_component_dependency,
  public_component_builder,
  component_builder_invalid_method_parameters,
  component_builder_invalid_method_type,
  wrong_arguments_of_build_method,
  component_builder_type_provided_multiple_times,
  component_builder_private_method,
}

extension JuggerErrorIdExt on JuggerErrorId {
  String toLink() {
    switch (this) {
      case JuggerErrorId.missing_build_method:
        return missingBuildMethod;
      case JuggerErrorId.wrong_type_of_build_method:
        return wrongTypeOfBuildMethod;
      case JuggerErrorId.missing_component_dependency:
        return missingComponentDependency;
      case JuggerErrorId.public_component_builder:
        return publicComponentBuilder;
      case JuggerErrorId.component_builder_invalid_method_parameters:
        return componentBuilderInvalidMethodParameters;
      case JuggerErrorId.component_builder_invalid_method_type:
        return componentBuilderInvalidMethodType;
      case JuggerErrorId.wrong_arguments_of_build_method:
        return wrongArgumentsOfBuildMethod;
      case JuggerErrorId.component_builder_type_provided_multiple_times:
        return componentBuilderTypeProvidesMultipleTimes;
      case JuggerErrorId.component_builder_private_method:
        return componentBuilderPrivateMethod;
    }
  }
}
