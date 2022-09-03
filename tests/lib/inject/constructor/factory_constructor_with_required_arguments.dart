// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  MyClass get myClass;
}

class MyClass {
  MyClass._();

  @inject
  factory MyClass.create({required MyClass1 myClass1}) {
    return MyClass._();
  }
}

class MyClass1 {
  @inject
  const MyClass1();
}
