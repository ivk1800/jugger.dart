import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_example/src/di/app_component.dart';
import 'package:flutter_example/src/di/app_component.jugger.dart';
import 'package:flutter_example/src/screen/packages_list/packages_list_bloc.dart';
import 'package:flutter_example/src/screen/packages_list/packages_list_page.dart';
import 'package:flutter_example/src/screen/packages_list/packages_list_screen_scope.dart';
import 'package:jugger/jugger.dart' as j;

@immutable
class PackagesListScreenFactory {
  @j.inject
  const PackagesListScreenFactory({
    required IAppComponent appComponent,
  }) : _appComponent = appComponent;

  final IAppComponent _appComponent;

  Widget create() {
    return PackagesListScreenScope(
      child: const BlocProvider<PackagesListBloc>(
        create: PackagesListScreenScope.getPackagesListBloc,
        child: PackagesListPage(),
      ),
      create: () {
        return _appComponent.createPackagesListScreenComponent(
          JuggerSubcomponent$PackagesListScreenComponentBuilder(),
        );
      },
    );
  }
}
