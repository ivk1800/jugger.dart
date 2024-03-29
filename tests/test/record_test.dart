import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test(
    'record type in provide method',
    () async {
      await checkBuilderOfFile(
        'record/record_type_in_provide_method',
      );
    },
  );

  test(
    'record type in provide method as parameter',
    () async {
      await checkBuilderOfFile(
        'record/record_type_in_provide_method_as_parameter',
      );
    },
  );

  test(
    'record type in component builder',
    () async {
      await checkBuilderOfFile(
        'record/record_type_in_component_builder',
      );
    },
  );

  test(
    'record type in multibindings',
    () async {
      await checkBuilderOfFile(
        'record/record_type_in_multibindings',
      );
    },
  );

  test(
    'record type in injected constructor',
    () async {
      await checkBuilderOfFile(
        'record/record_type_in_injected_constructor',
      );
    },
  );

  test(
    'record type in parent component',
    () async {
      await checkBuilderOfFile(
        'record/record_type_in_parent_component',
      );
    },
  );

  test(
    'record type in another component',
    () async {
      await checkBuilderOfFile(
        'record/record_type_in_another_component',
      );
    },
  );

  test(
    'record type with qualifier',
    () async {
      await checkBuilderOfFile(
        'record/record_type_with_qualifier',
      );
    },
  );

  test(
    'empty record type',
    () async {
      await checkBuilderOfFile(
        'record/empty_record_type',
      );
    },
  );

  test(
    'record type with both positional and named fields',
    () async {
      await checkBuilderOfFile(
        'record/record_type_with_both_positional_and_named_fields',
      );
    },
  );

  test(
    'record type with named fields',
    () async {
      await checkBuilderOfFile(
        'record/record_type_with_named_fields',
      );
    },
  );

  test(
    'record type with one positional field',
    () async {
      await checkBuilderOfFile(
        'record/record_type_with_one_positional_field',
      );
    },
  );

  test(
    'nested record type',
    () async {
      await checkBuilderOfFile(
        'record/nested_record_type',
      );
    },
  );

  test(
    'record type with nullable field',
    () async {
      await checkBuilderOfFile(
        'record/record_type_with_nullable_field',
      );
    },
  );
}
