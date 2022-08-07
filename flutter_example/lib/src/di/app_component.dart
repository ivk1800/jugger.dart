import 'package:flutter_example/src/di/logger_module.dart';
import 'package:flutter_example/src/screen/packages_list/di/packages_list_screen_component.dart';
import 'package:flutter_example/src/screen/packages_list/di/packages_list_screen_component_builder.dart';
import 'package:flutter_example/src/screen/packages_list/packages_list_screen_factory.dart';
import 'package:jugger/jugger.dart' as j;

import 'app_component_builder.dart';
import 'app_module.dart';
import 'data_module.dart';
import 'route_module.dart';
import 'scope.dart';

@j.Component(
  modules: <Type>[
    RouteModule,
    DataModule,
    AppModule,
    LoggerModule,
  ],
  builder: IAppComponentBuilder,
)
@applicationScope
abstract class IAppComponent {
  // getter example
  PackagesListScreenFactory get packagesListScreenFactory;

  @j.subcomponentFactory
  IPackagesListScreenComponent createPackagesListScreenComponent(
    IPackagesListScreenComponentBuilder builder,
  );
}
