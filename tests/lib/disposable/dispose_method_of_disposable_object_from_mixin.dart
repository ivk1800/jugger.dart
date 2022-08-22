// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component()
@singleton
abstract class AppComponent {
  MyClass get myClass;

  Future<void> dispose();
}

@singleton
@disposable
class MyClass with MyMixin {
  @inject
  const MyClass();
}

mixin MyMixin {
  void dispose() {}
}
