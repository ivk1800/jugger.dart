// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  builder: MyComponentBuilder,
)
abstract class MyComponent {
  MyEnum get myEnum;
}

@componentBuilder
abstract class MyComponentBuilder {
  MyComponentBuilder setMyEnum(MyEnum value);

  MyComponent build();
}

enum MyEnum {
  first,
}
