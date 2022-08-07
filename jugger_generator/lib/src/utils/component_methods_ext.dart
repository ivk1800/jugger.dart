import 'package:collection/collection.dart';

import '../generator/wrappers.dart';

extension ComponentMethodsExt on List<ComponentMethod> {
  /// Returns all properties of the component and validate them. The
  /// client must check that the element is a component.
  List<PropertyObjectAccessor> getComponentPropertiesAccessors() {
    return whereType<PropertyObjectAccessor>()
        .cast<PropertyObjectAccessor>()
        .toList(growable: false);
  }

  /// Returns all provide methods of the component and validate them.The client
  /// must check that the element is a component.
  List<MethodObjectAccessor> getComponentMethodsAccessors() {
    return whereType<MethodObjectAccessor>()
        .cast<MethodObjectAccessor>()
        .toList(growable: false);
  }

  /// Returns all methods of component for inject and validate them. The client
  /// must check that the element is a module.
  List<MemberInjectorMethod> getComponentMemberInjectorMethods() {
    return whereType<MemberInjectorMethod>()
        .cast<MemberInjectorMethod>()
        .toList(growable: false);
  }

  DisposeMethod? getDisposeMethod() {
    return firstWhereOrNull(
      (ComponentMethod method) => method is DisposeMethod,
    ) as DisposeMethod?;
  }
}
