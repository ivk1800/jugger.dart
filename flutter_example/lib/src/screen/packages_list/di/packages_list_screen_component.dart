import 'package:flutter_example/src/di/scope.dart';
import 'package:flutter_example/src/screen/packages_list/packages_list_bloc.dart';
import 'package:jugger/jugger.dart' as j;

import 'packages_list_screen_component_builder.dart';
import 'packages_list_screen_module.dart';

@j.Subcomponent(
  modules: <Type>[PackagesListScreenModule],
  builder: IPackagesListScreenComponentBuilder,
)
@screenScope
abstract class IPackagesListScreenComponent {
  PackagesListBloc getPackagesListBloc();
}
