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
  });

  group('non lazy', () {
    test('simple', () async {
      await checkBuilderOfFile('non_lazy/non_lazy_simple');
    });

    test('without non lazy', () async {
      await checkBuilderOfFile('non_lazy/non_lazy_without_non_lazy');
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
  });

  group('subcomponent', () {
    test('simple', () async {
      await checkBuilderOfFile('subcomponent/simple_subcomponent');
    });
  });

  group('component', () {
    test('build instance dependency', () async {
      await checkBuilderOfFile(
          'component/component_with_build_instance_dependency');
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
}
