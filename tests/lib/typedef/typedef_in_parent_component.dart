// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';
import 'package:tests/util/scopes.dart';

@Component(modules: <Type>[ParentModule])
abstract class ParentComponent {
  @subcomponentFactory
  ChildComponent createChildComponent();
}

@module
abstract class ParentModule {
  @provides
  static MyTypedef provideMyTypedef() => 0;
}

@Subcomponent()
@scope2
abstract class ChildComponent {
  int get myTypedef;
}

typedef MyTypedef = int;
