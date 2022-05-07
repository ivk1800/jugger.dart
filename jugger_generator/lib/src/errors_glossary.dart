// ignore_for_file: constant_identifier_names

const String _glossary =
    'https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md';
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
const String publicComponent = '$_glossary#public_component';
const String abstractComponent = '$_glossary#abstract_component';
const String invalidComponentDependency =
    '$_glossary#invalid_component_dependency';
const String componentDependHimself = '$_glossary#component_depend_himself';
const String publicModule = '$_glossary#public_module';
const String abstractModule = '$_glossary#abstract_module';
const String moduleAnnotationRequired = '$_glossary#module_annotation_required';
const String repeatedModules = '$_glossary#repeated_modules';
const String missingProvidesAnnotation =
    '$_glossary#missing_provides_annotation';
const String missingBindAnnotation = '$_glossary#missing_bind_annotation';
const String unsupportedMethodType = '$_glossary#unsupported_method_type';
const String privateMethodOfModule = '$_glossary#private_method_of_module';
const String bindWrongType = '$_glossary#bind_wrong_type';
const String ambiguityOfProvideMethod =
    '$_glossary#ambiguity_of_provide_method';
const String typeNotSupported = '$_glossary#type_not_supported';

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
  public_component,
  abstract_component,
  invalid_component_dependency,
  component_depend_himself,
  public_module,
  abstract_module,
  module_annotation_required,
  repeated_modules,
  missing_provides_annotation,
  missing_bind_annotation,
  unsupported_method_type,
  private_method_of_module,
  bind_wrong_type,
  ambiguity_of_provide_method,
  type_not_supported,
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
      case JuggerErrorId.public_component:
        return publicComponent;
      case JuggerErrorId.abstract_component:
        return abstractComponent;
      case JuggerErrorId.invalid_component_dependency:
        return invalidComponentDependency;
      case JuggerErrorId.component_depend_himself:
        return componentDependHimself;
      case JuggerErrorId.public_module:
        return publicModule;
      case JuggerErrorId.abstract_module:
        return abstractModule;
      case JuggerErrorId.module_annotation_required:
        return moduleAnnotationRequired;
      case JuggerErrorId.repeated_modules:
        return repeatedModules;
      case JuggerErrorId.missing_provides_annotation:
        return missingProvidesAnnotation;
      case JuggerErrorId.unsupported_method_type:
        return unsupportedMethodType;
      case JuggerErrorId.private_method_of_module:
        return privateMethodOfModule;
      case JuggerErrorId.missing_bind_annotation:
        return missingBindAnnotation;
      case JuggerErrorId.bind_wrong_type:
        return bindWrongType;
      case JuggerErrorId.ambiguity_of_provide_method:
        return ambiguityOfProvideMethod;
      case JuggerErrorId.type_not_supported:
        return typeNotSupported;
    }
  }
}