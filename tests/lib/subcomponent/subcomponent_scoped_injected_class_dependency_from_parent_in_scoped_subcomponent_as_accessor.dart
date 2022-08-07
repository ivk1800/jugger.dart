// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';
import 'package:tests/util/scopes.dart';

@Component()
@scope1
abstract class MyComponent {
  @subcomponentFactory
  MySubcomponent createMySubcomponent();

  MyClass getMyClass();

  MyClass get myClass;
}

@Subcomponent()
abstract class MySubcomponent {
  MyClass getMyClass();

  MyClass get myClass;
}

@scope1
class MyClass {
  @inject
  const MyClass();
}
