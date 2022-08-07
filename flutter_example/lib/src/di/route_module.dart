import 'package:flutter/material.dart';
import 'package:flutter_example/src/app/app_router.dart';
import 'package:flutter_example/src/di/scope.dart';
import 'package:flutter_example/src/screen/package_details/package_details_screen_factory.dart';
import 'package:flutter_example/src/screen/packages_list/packages_list_screen_router.dart';
import 'package:jugger/jugger.dart' as j;

@j.module
abstract class RouteModule {
  // provide method example
  @j.provides
  @applicationScope
  static AppRouter provideAppRouter(
    GlobalKey<NavigatorState> navigationKey,
    PackageDetailsScreenFactory packageDetailsScreenFactory,
  ) =>
      AppRouter(
        navigationKey: navigationKey,
        packageDetailsScreenFactory: packageDetailsScreenFactory,
      );

  // bind method example
  @applicationScope
  @j.binds
  IPackagesListScreenRouter bindPackagesListScreenRouter(AppRouter impl);
}
