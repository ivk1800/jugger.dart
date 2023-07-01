// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  builder: MyComponentBuilder,
)
abstract class MyComponent {
  (String, int) get myRecord;
}

@componentBuilder
abstract class MyComponentBuilder {
  MyComponentBuilder setRecord((String, int) value);

  MyComponent build();
}
