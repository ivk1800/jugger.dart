// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  MyClass getMyClass();
}

@module
abstract class AppModule {
  @provides
  static int provideInt1() => 0;

  @provides
  @myQualifier
  static int provideInt2() => 0;

  @provides
  @Named('name')
  static int provideInt3() => 0;
}

class MyClass {
  @inject
  const MyClass();

  @inject
  void init(@myQualifier int i, @Named('name') int i2, int i3) {}
}

@qualifier
class MyQualifier {
  const MyQualifier();
}

const MyQualifier myQualifier = MyQualifier();
