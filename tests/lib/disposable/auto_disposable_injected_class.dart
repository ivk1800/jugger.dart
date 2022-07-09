// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  MyClass getMyClass();

  Future<void> dispose();
}

@singleton
@disposable
class MyClass {
  @inject
  const MyClass();

  void dispose() {}
}
