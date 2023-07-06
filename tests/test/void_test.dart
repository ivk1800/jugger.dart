import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test(
    'void type in provide method',
    () async {
      await checkBuilderOfFile(
        'void/void_type_in_provide_method',
      );
    },
  );

  test(
    'void type in provide method as parameter',
    () async {
      await checkBuilderOfFile(
        'void/void_type_in_provide_method_as_parameter',
      );
    },
  );

  test(
    'void type in injected constructor',
    () async {
      await checkBuilderOfFile(
        'void/void_type_in_injected_constructor',
      );
    },
  );

  test(
    'void type in parent component',
    () async {
      await checkBuilderOfFile(
        'void/void_type_in_parent_component',
      );
    },
  );

  test(
    'void type in another component',
    () async {
      await checkBuilderOfFile(
        'void/void_type_in_another_component',
      );
    },
  );

  test(
    'void type with qualifier',
    () async {
      await checkBuilderOfFile(
        'void/void_type_with_qualifier',
      );
    },
  );
}
