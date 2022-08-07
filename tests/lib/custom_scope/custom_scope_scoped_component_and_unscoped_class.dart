// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component()
@myScope
abstract class AppComponent {
  MyClass get myClass;
}

class MyClass {
  @inject
  const MyClass();
}

@scope
class MyScope {
  const MyScope._();
}

const MyScope myScope = MyScope._();
