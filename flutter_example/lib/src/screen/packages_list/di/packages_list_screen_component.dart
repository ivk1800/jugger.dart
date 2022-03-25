import 'package:flutter_example/src/di/app_component.dart';
import 'package:flutter_example/src/screen/packages_list/packages_list_bloc.dart';
import 'package:jugger/jugger.dart' as j;

import 'packages_list_screen_module.dart';

@j.Component(
  dependencies: <Type>[IAppComponent],
  modules: <Type>[PackagesListScreenModule],
)
abstract class IPackagesListScreenComponent {
  PackagesListBloc getPackagesListBloc();
}

@j.componentBuilder
abstract class IPackagesListScreenComponentBuilder {
  IPackagesListScreenComponentBuilder appComponent(IAppComponent value);

  IPackagesListScreenComponent build();
}
