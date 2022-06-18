import 'package:build/build.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('disposable', () {
    test('dispose method of disposable object from mixin', () async {
      await checkBuilderOfFile(
        'disposable/dispose_method_of_disposable_object_from_mixin',
      );
    });

    test('auto disposable argument class', () async {
      await checkBuilderOfFile('disposable/auto_disposable_argument_class');
    });

    test('delegated disposable argument class', () async {
      await checkBuilderOfFile(
        'disposable/delegated_disposable_argument_class',
      );
    });

    test('delegated disposable provided class', () async {
      await checkBuilderOfFile(
        'disposable/delegated_disposable_provided_class',
      );
    });

    test('delegated disposable injected class', () async {
      await checkBuilderOfFile(
        'disposable/delegated_disposable_injected_class',
      );
    });

    test('dispose method of component from ancestor', () async {
      await checkBuilderOfFile(
        'disposable/dispose_method_of_component_from_ancestor',
      );
    });

    test('module with dispose handler include by multiple modules', () async {
      await checkBuilderOfFile(
        'disposable/module_with_dispose_handler_include_by_multiple_modules',
      );
    });

    test('auto disposable binded impl class', () async {
      await checkBuilderOfFile(
        'disposable/auto_disposable_binded_impl_class',
      );
    });

    test('auto disposable injected class', () async {
      await checkBuilderOfFile(
        'disposable/auto_disposable_injected_class',
      );
    });

    test('delegated disposable binded class', () async {
      await checkBuilderOfFile(
        'disposable/delegated_disposable_binded_class',
      );
    });

    test('dispose method of component from another interface', () async {
      await checkBuilderOfFile(
        'disposable/dispose_method_of_component_from_another_interface',
      );
    });

    test('void and async disposable handler', () async {
      await checkBuilderOfFile(
        'disposable/void_and_async_disposable_handler',
      );
    });
  });

  group('field name generation', () {
    test('should generate type names from module', () async {
      await checkBuilderResult(
        assets: {
          'my1.dart': '''
          class First {}
          ''',
          'my2.dart': '''
          class First {}
          ''',
        },
        mainContent: '''
import 'package:jugger/jugger.dart';
import 'my1.dart' as m1;
import 'my2.dart' as m2;

@Component(modules: <Type>[Module])
abstract class AppComponent {
  m1.First get first1;

  m2.First get first2;
}

@module
abstract class Module {
  @provides
  static m1.First provideFirst1() => m1.First();

  @provides
  static m2.First provideFirst2() => m2.First();
}
        ''',
        resultContent: () {
          return readAssetFile('fields_names/from_module');
        },
      );
    }, skip: true);
    test('should generate type names from component arguments', () async {
      await checkBuilderResult(
        assets: {
          'my1.dart': '''
          class First {}
          ''',
          'my2.dart': '''
          class First {}
          ''',
        },
        mainContent: '''
import 'package:jugger/jugger.dart';
import 'my1.dart' as m1;
import 'my2.dart' as m2;

@Component()
abstract class AppComponent {
  m1.First get first1;

  m2.First get first2;
}

@componentBuilder
abstract class AppComponentBuilder {
  AppComponentBuilder setFirst1(m1.First first);

  AppComponentBuilder setFirst2(m2.First first);

  AppComponent build();
}
        ''',
        resultContent: () {
          return readAssetFile('fields_names/from_component_arguments');
        },
      );
    });
    test('should generate type names from injected constructor', () async {
      await checkBuilderResult(
        assets: {
          'my1.dart': '''
import 'package:jugger/jugger.dart';

class First {
  @inject
  const First();
}
          ''',
          'my2.dart': '''
import 'package:jugger/jugger.dart';

class First {
  @inject
  const First();
}
          ''',
        },
        mainContent: '''
// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';
import 'my1.dart' as m1;
import 'my2.dart' as m2;

@Component()
abstract class AppComponent {
  m1.First get first1;

  m2.First get first2;
}
        ''',
        resultContent: () {
          return readAssetFile('fields_names/from_injected_constructor');
        },
      );
    });
  }, skip: true);

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

    test(
      'should use provide method in priority than injected constructor',
      () async {
        await checkBuilderOfFile(
          'provides/provides_method_priority_injected_constructor',
        );
      },
    );
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

    test('qualified multiple instances same type', () async {
      await checkBuilderOfFile(
          'qualifier/qualified_multiple_instances_same_type');
    });

    test('component arguments with custom qualifier', () async {
      await checkBuilderOfFile(
          'qualifier/component_arguments_with_custom_qualifier');
    });

    test('component arguments with named qualifier', () async {
      await checkBuilderOfFile(
          'qualifier/component_arguments_with_named_qualifier');
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

    test('injected constructor deep tree', () async {
      await checkBuilderOfFile(
          'inject/constructor/injected_constructor_deep_tree');
    });

    test('injected constructor deep tree 2', () async {
      await checkBuilderOfFile(
          'inject/constructor/injected_constructor_deep_tree_2');
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

    test('component without module', () async {
      await checkBuilderOfFile('component/component_without_module_2');
    });

    test('component with ancestor injectors', () async {
      await checkBuilderOfFile('component/component_with_ancestor_injectors');
    });

    test('component with ancestor methods', () async {
      await checkBuilderOfFile('component/component_with_ancestor_methods');
    });

    test('component with ancestor properties', () async {
      await checkBuilderOfFile('component/component_with_ancestor_properties');
    });

    test('component with overrided ancestor injectors', () async {
      await checkBuilderOfFile(
        'component/component_with_overrided_ancestor_injectors',
      );
    });

    test('component with overrided ancestor methods', () async {
      await checkBuilderOfFile(
        'component/component_with_overrided_ancestor_methods',
      );
    });

    test('component with overrided ancestor properties', () async {
      await checkBuilderOfFile(
        'component/component_with_overrided_ancestor_properties',
      );
    });

    test('component with implemented ancestors', () async {
      await checkBuilderOfFile(
        'component/component_with_implemented_ancestors',
      );
    });

    test('component with implemented and extended ancestors', () async {
      await checkBuilderOfFile(
        'component/component_with_implemented_and_extended_ancestors',
      );
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

    test('custom line length', () async {
      await checkBuilderOfFile(
        'build_config/custom_line_length',
        const BuilderOptions(
          <String, dynamic>{
            'generated_file_line_length': 120,
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

    test('injected method class which part of component', () async {
      await checkBuilderOfFile(
        'injected_method/injected_method_class_which_part_of_component',
      );
    });

    test('injected method class which not part of component', () async {
      await checkBuilderOfFile(
        'injected_method/injected_method_class_which_not_part_of_component',
      );
    });
  });

  group('module', () {
    test('module included by another modules', () async {
      await checkBuilderOfFile(
        'module/module_included_by_another_modules',
      );
    });

    test('module with includes', () async {
      await checkBuilderOfFile(
        'module/module_with_includes',
      );
    });

    test('module includes by another module and component', () async {
      await checkBuilderOfFile(
        'module/module_includes_by_another_module_and_component',
      );
    });
  });
}
