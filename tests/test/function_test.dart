import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test(
    'function_type_with_both_required_and_optional_named_parameters',
    () async {
      await checkBuilderOfFile(
        'function/function_type_with_both_required_and_optional_named_parameters',
      );
    },
  );

  test(
    'function_type_with_empty_parameters',
    () async {
      await checkBuilderOfFile(
        'function/function_type_with_empty_parameters',
      );
    },
  );

  test(
    'function_type_with_optional_named_parameters',
    () async {
      await checkBuilderOfFile(
        'function/function_type_with_optional_named_parameters',
      );
    },
  );

  test(
    'function_type_with_optional_positional_parameters',
    () async {
      await checkBuilderOfFile(
        'function/function_type_with_optional_positional_parameters',
      );
    },
  );

  test(
    'function_type_with_required_and_optional_positional_parameter',
    () async {
      await checkBuilderOfFile(
        'function/function_type_with_required_and_optional_positional_parameter',
      );
    },
  );

  test(
    'function_type_with_required_named_parameters',
    () async {
      await checkBuilderOfFile(
        'function/function_type_with_required_named_parameters',
      );
    },
  );

  test(
    'function_type_with_type_parameter',
    () async {
      await checkBuilderOfFile(
        'function/function_type_with_type_parameter',
      );
    },
  );

  test(
    'function_type_in_another_component',
    () async {
      await checkBuilderOfFile(
        'function/function_type_in_another_component',
      );
    },
  );

  test(
    'function_type_in_component_builder',
    () async {
      await checkBuilderOfFile(
        'function/function_type_in_component_builder',
      );
    },
  );

  test(
    'function_type_in_injected_constructor',
    () async {
      await checkBuilderOfFile(
        'function/function_type_in_injected_constructor',
      );
    },
  );

  test(
    'function_type_in_multibindings',
    () async {
      await checkBuilderOfFile(
        'function/function_type_in_multibindings',
      );
    },
  );

  test(
    'function_type_in_parent_component',
    () async {
      await checkBuilderOfFile(
        'function/function_type_in_parent_component',
      );
    },
  );

  test(
    'function_type_in_provide_method',
    () async {
      await checkBuilderOfFile(
        'function/function_type_in_provide_method',
      );
    },
  );

  test(
    'function_type_in_provide_method_as_parameter',
    () async {
      await checkBuilderOfFile(
        'function/function_type_in_provide_method_as_parameter',
      );
    },
  );

  test(
    'function_type_with_qualifier',
    () async {
      await checkBuilderOfFile(
        'function/function_type_with_qualifier',
      );
    },
  );
}
