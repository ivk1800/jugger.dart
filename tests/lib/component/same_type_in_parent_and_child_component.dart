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
  static (String, int) provideMyRecord() => ('', 0);
}

@Subcomponent(modules: <Type>[ChildModule])
@scope2
abstract class ChildComponent {
  (String, int) get myRecord;

  (String, String) get myRecord2;
}

@module
abstract class ChildModule {
  @provides
  static (String, String) provideMyRecord() => ('', '');
}
