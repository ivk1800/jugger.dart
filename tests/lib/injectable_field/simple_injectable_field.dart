// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

class InjectableClass {
  @inject
  late String helloString;
}

////////////////////////////////////////////////////////////////////////////////

@Component(modules: <Type>[AppModule])
@singleton
abstract class AppComponent {
  void inject(InjectableClass c);
}

@module
abstract class AppModule {
  @singleton
  @provides
  static String provideString() => 'hello';
}
