import 'package:flutter/material.dart';
import 'package:flutter_example/src/screen/package_details/package_details_screen_factory.dart';
import 'package:flutter_example/src/screen/packages_list/packages_list_screen_router.dart';

class AppRouter implements IPackagesListScreenRouter {
  AppRouter({
    required GlobalKey<NavigatorState> navigationKey,
    required PackageDetailsScreenFactory packageDetailsScreenFactory,
  })  : _navigationKey = navigationKey,
        _packageDetailsScreenFactory = packageDetailsScreenFactory;

  final GlobalKey<NavigatorState> _navigationKey;
  final PackageDetailsScreenFactory _packageDetailsScreenFactory;

  @override
  void toPackageDetails(String name) {
    final Widget screenWidget = _packageDetailsScreenFactory.create(name);

    // TODO(Ivan): handle nullable state
    _navigationKey.currentState?.push(MaterialPageRoute<Object?>(
      builder: (_) => screenWidget,
    ));
  }
}
