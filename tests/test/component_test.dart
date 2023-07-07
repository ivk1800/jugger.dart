import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test(
    'same type in parent and child component',
    () async {
      await checkBuilderOfFile(
        'component/same_type_in_parent_and_child_component',
      );
    },
  );
}
