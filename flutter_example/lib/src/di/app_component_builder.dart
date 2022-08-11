import 'package:flutter/widgets.dart';
import 'package:jugger/jugger.dart' as j;

import 'app_component.dart';

// component builder example
@j.componentBuilder
abstract class IAppComponentBuilder {
  IAppComponentBuilder navigationKey(GlobalKey<NavigatorState> value);

  IAppComponent build();
}
