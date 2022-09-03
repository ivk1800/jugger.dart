// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  MyClass get myClass;
}

class MyClass {
  @inject
  const MyClass.test({required this.myClass1});

  final MyClass1 myClass1;
}

class MyClass1 {
  @inject
  const MyClass1();
}
