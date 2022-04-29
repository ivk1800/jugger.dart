// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

class InjectableClass {
  @inject
  void init(String string) {}
}

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  void inject(InjectableClass target);
}

@module
abstract class AppModule {
  @provides
  static String provideString() => 'hello';
}
