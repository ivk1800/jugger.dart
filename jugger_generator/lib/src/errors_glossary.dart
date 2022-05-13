// ignore_for_file: constant_identifier_names

import 'package:analyzer/dart/element/type.dart';

import 'generator/tag.dart';

// region errors

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
const String componentBuilderTypeProvidedMultipleTimes =
    '$_glossary#component_builder_type_provided_multiple_times';
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
const String ambiguityOfInjectedConstructor =
    '$_glossary#ambiguity_of_injected_constructor';
const String invalidParametersTypes = '$_glossary#invalid_parameters_types';
const String multipleProvidersForType =
    '$_glossary#multiple_providers_for_type';
const String invalidInjectedConstructor =
    '$_glossary#invalid_injected_constructor';
const String invalidMethodOfComponent =
    '$_glossary#invalid_method_of_component';
const String missingComponentBuilder = '$_glossary#missing_component_builder';
const String circularDependency = '$_glossary#circular_dependency';
const String providerNotFound = '$_glossary#provider_not_found';
const String unusedGeneratedProviders = '$_glossary#unused_generated_providers';
const String multipleQualifiers = '$_glossary#multiple_qualifiers';
const String invalidInjectableMethod = '$_glossary#invalid_injectable_method';
const String invalidInjectedMethod = '$_glossary#invalid_injected_method';
const String invalidBindMethod = '$_glossary#invalid_bind_method';
const String modulesCircularDependency =
    '$_glossary#modules_circular_dependency';
const String multipleModuleAnnotations =
    '$_glossary#multiple_module_annotations';

// endregion errors

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
  ambiguity_of_injected_constructor,
  invalid_parameters_types,
  multiple_providers_for_type,
  invalid_injected_constructor,
  missing_component_builder,
  invalid_method_of_component,
  circular_dependency,
  provider_not_found,
  unused_generated_providers,
  multiple_qualifiers,
  invalid_injectable_method,
  invalid_injected_method,
  invalid_bind_method,
  circular_modules_dependency,
  multiple_module_annotations,
}

// TODO: support Enhanced enums with members in dart 2.17.0
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
        return componentBuilderTypeProvidedMultipleTimes;
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
      case JuggerErrorId.ambiguity_of_injected_constructor:
        return ambiguityOfInjectedConstructor;
      case JuggerErrorId.invalid_parameters_types:
        return invalidParametersTypes;
      case JuggerErrorId.multiple_providers_for_type:
        return multipleProvidersForType;
      case JuggerErrorId.invalid_injected_constructor:
        return invalidInjectedConstructor;
      case JuggerErrorId.missing_component_builder:
        return missingComponentBuilder;
      case JuggerErrorId.invalid_method_of_component:
        return invalidMethodOfComponent;
      case JuggerErrorId.circular_dependency:
        return circularDependency;
      case JuggerErrorId.provider_not_found:
        return providerNotFound;
      case JuggerErrorId.unused_generated_providers:
        return unusedGeneratedProviders;
      case JuggerErrorId.multiple_qualifiers:
        return multipleQualifiers;
      case JuggerErrorId.invalid_injectable_method:
        return invalidInjectableMethod;
      case JuggerErrorId.invalid_injected_method:
        return invalidInjectedMethod;
      case JuggerErrorId.invalid_bind_method:
        return invalidBindMethod;
      case JuggerErrorId.circular_modules_dependency:
        return modulesCircularDependency;
      case JuggerErrorId.multiple_module_annotations:
        return multipleModuleAnnotations;
    }
  }
}

String buildErrorMessage({
  required JuggerErrorId error,
  required String message,
}) =>
    '${error.name}:\n$message\nExplanation of Error: ${error.toLink()}';

String buildUnexpectedErrorMessage({
  required String message,
}) =>
    '$message\nUnexpected error, please report the issue: https://github.com/ivk1800/jugger.dart/issues/new?assignees=&labels=&template=code-generation-error.md&title=';

String buildProviderNotFoundMessage(DartType type, Tag? tag) {
  return buildErrorMessage(
    error: JuggerErrorId.provider_not_found,
    message:
        'Provider for $type ${tag != null ? 'with qualifier ${tag.originalId} ' : ''}not found.',
  );
}
