import 'package:flutter/widgets.dart';
import 'package:flutter_example/src/app/data/data.dart';
import 'package:flutter_example/src/screen/packages_list/packages_list_screen_factory.dart';
import 'package:flutter_example/src/screen/packages_list/packages_list_screen_router.dart';
import 'package:jugger/jugger.dart' as j;

import 'app_module.dart';
import 'data_module.dart';
import 'route_module.dart';

@j.Component(
  modules: <Type>[
    RouteModule,
    DataModule,
    AppModule,
  ],
)
abstract class IAppComponent {
  // getter example
  PackagesListScreenFactory get packagesListScreenFactory;

  // method example
  IPackagesListScreenRouter getPackagesListScreenRouter();

  IPackagesRepository getPackagesRepository();
}

// component builder example
@j.componentBuilder
abstract class IAppComponentBuilder {
  IAppComponentBuilder navigationKey(GlobalKey<NavigatorState> value);

  IAppComponent build();
}
