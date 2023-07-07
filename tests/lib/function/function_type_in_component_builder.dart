// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  builder: MyComponentBuilder,
)
abstract class MyComponent {
  void Function() get myFunction;
}

@componentBuilder
abstract class MyComponentBuilder {
  MyComponentBuilder setFunction(void Function() value);

  MyComponent build();
}
