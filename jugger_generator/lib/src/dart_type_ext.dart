import 'package:analyzer/dart/element/type.dart';

extension DartTypeExt on DartType {
  bool get isProvider {
    return element!.library!.location!.components.any(
          (String component) => component == 'package:jugger/src/provider.dart',
        ) &&
        element!.name == 'IProvider';
  }
}
