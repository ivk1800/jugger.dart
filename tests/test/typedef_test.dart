import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test(
    'typedef_in_bind_method',
    () async {
      await checkBuilderOfFile(
        'typedef/typedef_in_bind_method',
      );
    },
  );

  test(
    'typedef_in_bind_method_as_parameter',
    () async {
      await checkBuilderOfFile(
        'typedef/typedef_in_bind_method_as_parameter',
      );
    },
  );

  test(
    'typedef_in_injected_constructor',
    () async {
      await checkBuilderOfFile(
        'typedef/typedef_in_injected_constructor',
      );
    },
  );

  test(
    'typedef_in_multibindings',
    () async {
      await checkBuilderOfFile(
        'typedef/typedef_in_multibindings',
      );
    },
  );

  test(
    'typedef_in_parent_component',
    () async {
      await checkBuilderOfFile(
        'typedef/typedef_in_parent_component',
      );
    },
  );

  test(
    'typedef_in_provide_method',
    () async {
      await checkBuilderOfFile(
        'typedef/typedef_in_provide_method',
      );
    },
  );

  test(
    'typedef_in_provide_method_as_parameter',
    () async {
      await checkBuilderOfFile(
        'typedef/typedef_in_provide_method_as_parameter',
      );
    },
  );

  test(
    'typedef_with_qualifier',
    () async {
      await checkBuilderOfFile(
        'typedef/typedef_with_qualifier',
      );
    },
  );
}
