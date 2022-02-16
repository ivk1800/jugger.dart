import 'package:analyzer/dart/element/type.dart';

extension DartTypeExt on DartType {
  bool get isProvider {
    if (element == null) {
      return false;
    }

    return element!.library!.location!.components.any(
          (String component) => component == 'package:jugger/src/provider.dart',
        ) &&
        element!.name == 'IProvider';
  }

  DartType get providerType {
    final InterfaceType interfaceType = this as InterfaceType;
    assert(interfaceType.typeArguments.length == 1);

    return interfaceType.typeArguments.first;
  }
}
