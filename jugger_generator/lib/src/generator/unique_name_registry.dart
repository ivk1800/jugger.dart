import 'package:analyzer/dart/element/type.dart';

import '../utils/dart_type_ext.dart';
import '../utils/utils.dart';

class UniqueIdGenerator {
  final List<Object> _ids = <Object>[];

  int generate(Object o) {
    final String id = generateMd5(o.toString());

    if (!_ids.contains(id)) {
      _ids.add(id);
    }

    return _ids.indexOf(id);
  }
}
