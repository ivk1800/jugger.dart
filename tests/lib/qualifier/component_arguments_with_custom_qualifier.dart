// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  MyClass getMyClass1();

  @myQualifier
  MyClass getMyClass2();
}

@componentBuilder
abstract class AppComponentBuilder {
  AppComponentBuilder setMyClass1(MyClass c);

  @myQualifier
  AppComponentBuilder setMyClass2(MyClass c);

  AppComponent build();
}

class MyClass {
  const MyClass();
}

@qualifier
class MyQualifier {
  const MyQualifier();
}

const MyQualifier myQualifier = MyQualifier();
