// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  builder: AppComponentBuilder,
)
abstract class AppComponent {
  @Named('1')
  MyClass getMyClass1();

  @Named('2')
  MyClass getMyClass2();

  MyClass getMyClass3();
}

@componentBuilder
abstract class AppComponentBuilder {
  @Named('1')
  AppComponentBuilder setMyClass1(MyClass c);

  @Named('2')
  AppComponentBuilder setMyClass2(MyClass c);

  AppComponentBuilder setMyClass3(MyClass c);

  AppComponent build();
}

class MyClass {
  const MyClass();
}
