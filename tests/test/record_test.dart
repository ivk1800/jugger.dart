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
}
