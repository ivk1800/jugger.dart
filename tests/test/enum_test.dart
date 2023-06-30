import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test(
    'enum type in injected constructor',
    () async {
      await checkBuilderOfFile(
        'enum/enum_type_in_injected_constructor',
      );
    },
  );

  test(
    'enum type in component builder',
    () async {
      await checkBuilderOfFile(
        'enum/enum_type_in_component_builder',
      );
    },
  );

  test(
    'enum type in provide method',
    () async {
      await checkBuilderOfFile(
        'enum/enum_type_in_provide_method',
      );
    },
  );

  test(
    'enum type in bind method',
    () async {
      await checkBuilderOfFile(
        'enum/enum_type_in_bind_method',
      );
    },
  );
}
