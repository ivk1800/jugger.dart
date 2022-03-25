import 'package:build/build.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('binds', () {
    test('from another module', () async {
      await checkBuilderOfFile('binds/binds_from_another_module');
    });

    test('from module', () async {
      await checkBuilderOfFile('binds/binds_from_module');
    });

    test('from injected constructor', () async {
      await checkBuilderOfFile('binds/binds_from_injected_constructor');
    });

    test('from injected constructor with singleton scope', () async {
      await checkBuilderOfFile(
        'binds/binds_from_injected_constructor_with_singleton_scope',
      );
    });

    test('binds as dependency in multiple different places', () async {
      await checkBuilderOfFile(
        'binds/binds_as_dependency_in_multiple_different_places',
      );
    });
  });

  group('non lazy', () {
    test('simple', () async {
      await checkBuilderOfFile('non_lazy/non_lazy_simple');
    });

    test('without non lazy', () async {
      await checkBuilderOfFile('non_lazy/non_lazy_without_non_lazy');
    });
  });

  group('provider', () {
    test('provider as dependency of constructor', () async {
      await checkBuilderOfFile(
        'provider/provider_as_dependency_of_constructor',
      );
    });

    test('provider as dependency of provides method', () async {
      await checkBuilderOfFile(
        'provider/provider_as_dependency_of_provides_method',
      );
    });

    test('provider and class as dependency together', () async {
      await checkBuilderOfFile(
        'provider/provider_and_class_as_dependency_together',
      );
    });

    test('only provider as dependency', () async {
      await checkBuilderOfFile(
        'provider/only_provider_as_dependency',
      );
    });

    test('multi providers as dependency', () async {
      await checkBuilderOfFile(
        'provider/multi_providers_as_dependency',
      );
    });

    test('provider with qualifier', () async {
      await checkBuilderOfFile(
        'provider/provider_with_qualifier',
      );
    });
  });

  group('provides', () {
    test('from component params', () async {
      await checkBuilderOfFile('provides/provides_from_component_params');
    });

    test('from injected constructor', () async {
      await checkBuilderOfFile('provides/provides_from_injected_constructor');
    });

    test('from module', () async {
      await checkBuilderOfFile('provides/provides_from_module');
    });

    test('component as method param', () async {
      await checkBuilderOfFile('provides/provides_component_as_method_param');
    });
  });

  group('component getter', () {
    test('simple', () async {
      await checkBuilderOfFile('getter/simple_getter');
    });
    test('from another component', () async {
      await checkBuilderOfFile('getter/getter_from_another_component');
    });
  });

  group('qualifier', () {
    test('custom qualifier', () async {
      await checkBuilderOfFile('qualifier/custom/custom_qualifier');
    });
    test('multiple custom qualifiers', () async {
      await checkBuilderOfFile('qualifier/custom/multiple_custom_qualifiers');
    });
    test('multiple named qualifiers', () async {
      await checkBuilderOfFile('qualifier/named/multiple_named_qualifiers');
    });
    test('named qualifier and default', () async {
      await checkBuilderOfFile('qualifier/named/named_qualifier_and_default');
    });
    test('different types with same qualifier', () async {
      await checkBuilderOfFile(
        'qualifier/named/different_types_with_same_qualifier',
      );
    });
    test('named qualifier provides param', () async {
      await checkBuilderOfFile(
          'qualifier/named/named_qualifier_provides_param');
    });
  });

  group('inject', () {
    test('empty injected constructor', () async {
      await checkBuilderOfFile('inject/constructor/empty_injected_constructor');
    });

    test('empty injected const constructor', () async {
      await checkBuilderOfFile(
          'inject/constructor/empty_injected_const_constructor');
    });

    test('injected const constructor with params', () async {
      await checkBuilderOfFile(
          'inject/constructor/injected_const_constructor_with_params');
    });

    test('injected constructor with singleton scope', () async {
      await checkBuilderOfFile(
          'inject/constructor/injected_constructor_with_singleton_scope');
    });

    test('injected constructor with positional params', () async {
      await checkBuilderOfFile(
          'inject/constructor/injected_constructor_with_positional_params');
    });
  });

  group('generics', () {
    test('provide simple list', () async {
      await checkBuilderOfFile('generics/provide_simple_list');
    });

    test('provide simple map', () async {
      await checkBuilderOfFile('generics/provide_simple_map');
    });

    test('provide complex generic', () async {
      await checkBuilderOfFile('generics/provide_complex_generic_type');
    });

    test('provide generic build instance', () async {
      await checkBuilderOfFile('generics/provide_generic_build_instance');
    });
  });

  group('subcomponent', () {
    test('simple', () async {
      await checkBuilderOfFile('subcomponent/simple_subcomponent');
    });
  });

  group('component', () {
    test('component with build instance dependency', () async {
      await checkBuilderOfFile(
          'component/component_with_build_instance_dependency');
    });

    test('component without module', () async {
      await checkBuilderOfFile('component/component_without_module');
    });

    test('component with multiple modules', () async {
      await checkBuilderOfFile('component/component_with_multiple_modules');
    });
  });

  group('interface prefix', () {
    test('remove interface prefix', () async {
      await checkBuilderOfFile(
        'build_config/remove_interface_prefix',
        const BuilderOptions(
          <String, dynamic>{
            'remove_interface_prefix_from_component_name': true,
          },
        ),
      );
    });

    test('not remove interface prefix', () async {
      await checkBuilderOfFile(
        'build_config/not_remove_interface_prefix',
        const BuilderOptions(
          <String, dynamic>{
            'remove_interface_prefix_from_component_name': false,
          },
        ),
      );
    });
  });

  group('injectable field', () {
    test('simple injectable field', () async {
      await checkBuilderOfFile(
        'injectable_field/simple_injectable_field',
      );
    });
  });

  group('injected method', () {
    test('injected deep parent methods and self', () async {
      await checkBuilderOfFile(
        'injected_method/injected_deep_parent_methods_and_self',
      );
    });

    test('injected empty method', () async {
      await checkBuilderOfFile(
        'injected_method/injected_empty_method',
      );
    });

    test('injected_method', () async {
      await checkBuilderOfFile(
        'injected_method/injected_method',
      );
    });

    test('injected method with multiple parameters', () async {
      await checkBuilderOfFile(
        'injected_method/injected_method_with_multiple_parameters',
      );
    });

    test('injected method with not empty constructor', () async {
      await checkBuilderOfFile(
        'injected_method/injected_method_with_not_empty_constructor',
      );
    });

    test('injected multiple methods', () async {
      await checkBuilderOfFile(
        'injected_method/injected_multiple_methods',
      );
    });

    test('injected multiple parent methods', () async {
      await checkBuilderOfFile(
        'injected_method/injected_multiple_parent_methods',
      );
    });

    test('injected overrided parent method', () async {
      await checkBuilderOfFile(
        'injected_method/injected_overrided_parent_method',
      );
    });

    test('injected parent method', () async {
      await checkBuilderOfFile(
        'injected_method/injected_parent_method',
      );
    });

    test('injected parent method and self', () async {
      await checkBuilderOfFile(
        'injected_method/injected_parent_method_and_self',
      );
    });

    test('injected method with qualifier parameters', () async {
      await checkBuilderOfFile(
        'injected_method/injected_method_with_qualifier_parameters',
      );
    });
  });
}
