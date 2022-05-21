// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(modules: <Type>[])
abstract class AppComponent {
  InjectedClass1 get hello;
}

class InjectedClass1 {
  @inject
  InjectedClass1({required this.injectedClass2Provider});

  final IProvider<InjectedClass2> injectedClass2Provider;
}

class InjectedClass2 {
  @inject
  InjectedClass2(this.injectedClass3);

  final InjectedClass3 injectedClass3;
}

class InjectedClass3 {
  @inject
  const InjectedClass3();
}
