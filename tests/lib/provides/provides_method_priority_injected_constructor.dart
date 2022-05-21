// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String getString();
}

@module
abstract class AppModule {
  @provides
  static String providerString(InjectedClass1 s) => '${s.runtimeType}';

  @provides
  static int providerIny() => 0;

  @provides
  static InjectedClass1 provideInjectedClass1(int i) => InjectedClass1();
}

class InjectedClass1 {
  @inject
  InjectedClass1();
}
