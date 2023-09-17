import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test(
    'mixin type binds from injected constructor',
    () async {
      await checkBuilderOfFile(
        'mixin/mixin_type_binds_from_injected_constructor',
      );
    },
  );

  test(
    'mixin type binds from module',
    () async {
      await checkBuilderOfFile(
        'mixin/mixin_type_binds_from_module',
      );
    },
  );

  test(
    'mixin type in another component',
    () async {
      await checkBuilderOfFile(
        'mixin/mixin_type_in_another_component',
      );
    },
  );

  test(
    'mixin type in parent component',
    () async {
      await checkBuilderOfFile(
        'mixin/mixin_type_in_parent_component',
      );
    },
  );

  test(
    'mixin type in provide method',
    () async {
      await checkBuilderOfFile(
        'mixin/mixin_type_in_provide_method',
      );
    },
  );

  test(
    'mixin_type_in_provide_method_as_parameter',
    () async {
      await checkBuilderOfFile(
        'mixin/mixin_type_in_provide_method_as_parameter',
      );
    },
  );

  test(
    'mixin type with qualifier',
    () async {
      await checkBuilderOfFile(
        'mixin/mixin_type_with_qualifier',
      );
    },
  );
}
