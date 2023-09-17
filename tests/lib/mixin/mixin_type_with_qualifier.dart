// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[MyModule],
)
abstract class MyComponent {
  @myQualifier
  MyMixin get myMyMixin;
}

@module
abstract class MyModule {
  @provides
  @myQualifier
  static MyMixin provideMyMixin() => MyMixinImpl();
}

@qualifier
class MyQualifier {
  const MyQualifier();
}

const MyQualifier myQualifier = MyQualifier();

mixin MyMixin {}

class MyMixinImpl with MyMixin {}
