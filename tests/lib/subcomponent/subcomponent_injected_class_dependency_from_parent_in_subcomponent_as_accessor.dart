// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component()
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

class MyClass {
  @inject
  const MyClass();
}
